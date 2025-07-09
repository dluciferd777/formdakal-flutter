// lib/providers/exercise_provider.dart - ÇALIŞAN ADIM SAYACI
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../services/calorie_service.dart';
import 'achievement_provider.dart';

class ExerciseProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late AchievementProvider _achievementProvider;
  late UserProvider _userProvider;

  List<CompletedExercise> _completedExercises = [];
  int _dailySteps = 0;
  int _dailyActiveMinutes = 0;

  // BASIT ACCELEROMETER ADIM SAYACI
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  
  // ADIM ALGILIYOR MU?
  bool _stepDetectionActive = false;
  double _lastMagnitude = 0;
  DateTime? _lastStepTime;
  List<double> _magnitudeHistory = [];
  int _consecutiveSteps = 0;
  
  // AYARLAR - ÇALIŞMASI GARANTILI
  static const double _stepThreshold = 2.0; // Çok düşük eşik
  static const double _maxMagnitude = 15.0; // Sallama filtresi
  static const int _minStepGap = 200; // 200ms minimum adım aralığı
  static const int _maxStepGap = 1500; // 1.5 saniye maksimum
  static const int _historySize = 8; // Pattern için geçmiş

  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider) {
    loadData();
    _startStepCounter();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
  }

  List<CompletedExercise> get completedExercises => _completedExercises;
  int get dailySteps => _dailySteps;
  int get dailyActiveMinutes => _dailyActiveMinutes;

  /// BASIT AMA ÇALIŞAN ADIM SAYACI
  void _startStepCounter() {
    print('🚀 Basit adım sayacı başlıyor...');
    
    _accelerometerSubscription = userAccelerometerEvents.listen(
      _onAccelerometerData,
      onError: (error) {
        print('❌ Accelerometer hatası: $error');
        // 3 saniye sonra tekrar dene
        Timer(Duration(seconds: 3), _startStepCounter);
      },
      cancelOnError: false,
    );
    
    print('✅ Accelerometer aktif');
  }

  /// ACCELEROMETER VERİSİ - BASIT VE ETKİN
  void _onAccelerometerData(UserAccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();

    // Geçmişe ekle
    _magnitudeHistory.add(magnitude);
    if (_magnitudeHistory.length > _historySize) {
      _magnitudeHistory.removeAt(0);
    }

    // Çok yüksek hareket = telefon sallama (ENGELLE)
    if (magnitude > _maxMagnitude) {
      _stepDetectionActive = false;
      _consecutiveSteps = 0;
      return;
    }

    // Çok düşük hareket = durgun (ENGELLE)
    if (magnitude < _stepThreshold) {
      return;
    }

    // ADIM ALGILANABİLİR Mİ?
    if (_canDetectStep(magnitude, now)) {
      _recordStep(now);
    }

    _lastMagnitude = magnitude;
  }

  /// ADIM ALGILANABİLİR Mİ? - KOŞULLAR
  bool _canDetectStep(double magnitude, DateTime now) {
    // 1. ZAMAN KONTROLÜ
    if (_lastStepTime != null) {
      final timeDiff = now.difference(_lastStepTime!).inMilliseconds;
      
      // Çok hızlı (< 200ms)
      if (timeDiff < _minStepGap) {
        return false;
      }
      
      // Çok yavaş (> 1.5s) = yürüme durdu
      if (timeDiff > _maxStepGap) {
        _stepDetectionActive = false;
        _consecutiveSteps = 0;
      }
    }

    // 2. PEAK DETECTION (Tepe noktası)
    if (_magnitudeHistory.length < 3) {
      return false;
    }

    // Son 3 değer: önceki < şimdiki > bir önceki
    final len = _magnitudeHistory.length;
    final prev = _magnitudeHistory[len - 2];
    final current = magnitude;
    final prevPrev = _magnitudeHistory[len - 3];

    bool isPeak = current > prev && prev > prevPrev && current > (_stepThreshold + 1.0);

    // 3. PATTERN KONTROLÜ
    if (isPeak) {
      // İlk adım mı?
      if (!_stepDetectionActive) {
        _stepDetectionActive = true;
        _consecutiveSteps = 1;
        return true;
      } 
      // Devam eden adımlar
      else {
        _consecutiveSteps++;
        return true;
      }
    }

    return false;
  }

  /// ADIM KAYDET
  void _recordStep(DateTime now) {
    _lastStepTime = now;
    _dailySteps++;
    
    print('👣 ADIM KAYDEDILDI! Toplam: $_dailySteps (Magnitude: ${_magnitudeHistory.last.toStringAsFixed(2)})');
    
    _saveSteps();
    notifyListeners();
    _checkStepAchievements();
    
    // Her 100 adımda bir motivasyon
    if (_dailySteps % 100 == 0) {
      print('🎉 $_dailySteps adım tamamlandı!');
    }
  }

  /// BAŞARIMLAR
  void _checkStepAchievements() {
    if (_dailySteps >= 1000) {
      _achievementProvider.unlockAchievement('first_1000_steps');
    }
    if (_dailySteps >= 5000) {
      _achievementProvider.unlockAchievement('daily_step_goal');
    }
    if (_dailySteps >= 10000) {
      _achievementProvider.unlockAchievement('step_master');
    }
  }

  /// VERİ YÖNETİMİ
  Future<void> loadData() async {
    final exerciseJson = _prefs.getString(_exercisesKey);
    if (exerciseJson != null) {
      final List<dynamic> decoded = jsonDecode(exerciseJson);
      _completedExercises =
          decoded.map((item) => CompletedExercise.fromJson(item)).toList();
    }
    
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    _dailySteps = _prefs.getInt(_stepsKey + todayKey) ?? 0;
    _dailyActiveMinutes = _prefs.getInt(_minutesKey + todayKey) ?? 0;
    
    print('📂 Yüklenen günlük adım: $_dailySteps');
    notifyListeners();
  }

  Future<void> _saveSteps() async {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setInt(_stepsKey + todayKey, _dailySteps);
  }

  Future<void> _saveCompletedExercises() async {
    final jsonList =
        _completedExercises.map((exercise) => exercise.toJson()).toList();
    await _prefs.setString(_exercisesKey, jsonEncode(jsonList));
  }

  Future<void> addCompletedExercise(CompletedExercise exercise) async {
    _completedExercises.add(exercise);
    await _saveCompletedExercises();
    _checkWorkoutAchievements();
    notifyListeners();
  }

  Future<void> removeCompletedExercise(int index) async {
    if (index >= 0 && index < _completedExercises.length) {
      _completedExercises.removeAt(index);
      await _saveCompletedExercises();
      notifyListeners();
    }
  }

  Future<void> removeCompletedExerciseById(String id) async {
    _completedExercises.removeWhere((exercise) => exercise.id == id);
    await _saveCompletedExercises();
    notifyListeners();
  }

  void _checkWorkoutAchievements() {
    if (_completedExercises.length == 1) {
      _achievementProvider.unlockAchievement('first_workout');
    }
  }

  double getDailyBurnedCalories(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    double exerciseCalories = _completedExercises
        .where((exercise) =>
            exercise.completedAt.isAfter(startOfDay) &&
            exercise.completedAt.isBefore(endOfDay))
        .fold(0.0, (total, exercise) => total + exercise.burnedCalories);

    final userWeight = _userProvider.user?.weight ?? 70.0;
    double stepCalories = 0.0;
    
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final dateKey = date.toIso8601String().substring(0, 10);
    if (dateKey == todayKey && _dailySteps > 0 && userWeight > 0) {
      stepCalories = CalorieService.calculateStepCalories(_dailySteps, userWeight);
    }
    
    return exerciseCalories + stepCalories;
  }

  int getDailyExerciseMinutes(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _completedExercises
        .where((exercise) =>
            exercise.completedAt.isAfter(startOfDay) &&
            exercise.completedAt.isBefore(endOfDay))
        .fold(0, (total, exercise) => total + exercise.durationMinutes);
  }

  /// TEST FONKSİYONLARI
  Future<void> addManualSteps(int steps) async {
    _dailySteps += steps;
    await _saveSteps();
    _checkStepAchievements();
    notifyListeners();
    print('➕ Manuel $steps adım eklendi! Toplam: $_dailySteps');
  }

  Future<void> resetDailySteps() async {
    _dailySteps = 0;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.remove(_stepsKey + todayKey);
    notifyListeners();
    print('🔄 Adım sayacı sıfırlandı');
  }

  /// DEBUG BİLGİLERİ
  void printDebugInfo() {
    print('🐛 === ADIM SAYACI DEBUG ===');
    print('Aktif: $_stepDetectionActive');
    print('Günlük Adım: $_dailySteps');
    print('Son Magnitude: ${_lastMagnitude.toStringAsFixed(2)}');
    print('Consecutıve Steps: $_consecutiveSteps');
    print('Geçmiş: ${_magnitudeHistory.map((e) => e.toStringAsFixed(1)).join(", ")}');
    print('============================');
  }

  /// Tüm verileri zorla kaydet
  Future<void> forceSave() async {
    await _saveSteps();
    await _saveCompletedExercises();
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}