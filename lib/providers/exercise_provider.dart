// lib/providers/exercise_provider.dart - GELİŞTİRİLMİŞ ADIM SAYACI
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:pedometer/pedometer.dart';
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

  // ADIM SAYACI SİSTEMLERİ
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  
  // AKILLI PATTERN ALGILAMA
  List<double> _accelerometerBuffer = [];
  List<DateTime> _stepTimestamps = [];
  int _initialStepCount = 0;
  int _todayStartSteps = 0;
  bool _useSystemPedometer = true;
  
  // YÜRÜME PATTERN'İ ALGILAMA
  int _consecutiveHighReadings = 0;
  DateTime? _lastStepTime;
  bool _isWalkingPattern = false;
  
  // AYARLAR
  static const double _walkingThreshold = 2.5; // Yürüme için minimum ivme
  static const double _maxAcceleration = 25.0; // Sallama filtresi
  static const int _minTimeBetweenSteps = 300; // Minimum adım aralığı (ms)
  static const int _maxTimeBetweenSteps = 2000; // Maksimum adım aralığı (ms)
  static const int _patternBufferSize = 10; // Pattern analizi için buffer

  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';
  static const _initialStepsKey = 'initial_steps_';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider) {
    loadData();
    _initAdvancedStepCounter();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
  }

  List<CompletedExercise> get completedExercises => _completedExercises;
  int get dailySteps => _dailySteps;
  int get dailyActiveMinutes => _dailyActiveMinutes;

  /// GELİŞTİRİLMİŞ ADIM SAYACI - AKILLI PATTERN ALGILIYOR
  void _initAdvancedStepCounter() async {
    print('🚀 Gelişmiş adım sayacı başlatılıyor...');
    
    // Önce sistem pedometer'ı dene
    await _trySystemPedometer();
    
    // Sistem yoksa akıllı accelerometer kullan
    if (!_useSystemPedometer) {
      await _initSmartAccelerometer();
    }
  }

  /// Sistem Pedometer'ı Dene (En Doğru Yöntem)
  Future<void> _trySystemPedometer() async {
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onSystemStepCount,
        onError: (error) {
          print('❌ Sistem pedometer hatası: $error');
          _useSystemPedometer = false;
          _initSmartAccelerometer();
        },
        cancelOnError: false,
      );
      
      print('✅ Sistem pedometer aktif');
      _useSystemPedometer = true;
    } catch (e) {
      print('❌ Sistem pedometer başlatılamadı: $e');
      _useSystemPedometer = false;
      await _initSmartAccelerometer();
    }
  }

  /// Sistem Adım Sayacı Verisi
  void _onSystemStepCount(StepCount event) async {
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    
    if (_initialStepCount == 0) {
      _initialStepCount = event.steps;
      _todayStartSteps = _prefs.getInt(_initialStepsKey + todayKey) ?? event.steps;
      
      final savedDate = _prefs.getString('last_step_date') ?? '';
      if (savedDate != todayKey) {
        _todayStartSteps = event.steps;
        await _prefs.setInt(_initialStepsKey + todayKey, event.steps);
        await _prefs.setString('last_step_date', todayKey);
      }
    }

    final todaySteps = event.steps - _todayStartSteps;
    
    if (todaySteps >= 0 && todaySteps != _dailySteps) {
      _dailySteps = todaySteps;
      await _saveSteps();
      notifyListeners();
      _checkStepAchievements();
      print('📱 Sistem adım: $_dailySteps (Toplam: ${event.steps})');
    }
  }

  /// Akıllı Accelerometer (Fallback)
  Future<void> _initSmartAccelerometer() async {
    print('🧠 Akıllı accelerometer aktif');
    
    _accelerometerSubscription = userAccelerometerEvents.listen(
      _onSmartAccelerometerEvent,
      onError: (error) {
        print('❌ Accelerometer hatası: $error');
      },
      cancelOnError: false,
    );
  }

  /// AKILLI ACCELEROMETER - PATTERN ALGILIYOR
  void _onSmartAccelerometerEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();
    
    // Buffer'a ekle
    _accelerometerBuffer.add(magnitude);
    if (_accelerometerBuffer.length > _patternBufferSize) {
      _accelerometerBuffer.removeAt(0);
    }
    
    // Yürüme pattern'i kontrolü
    _analyzeWalkingPattern(magnitude, now);
  }

  /// YÜRÜME PATTERN'İ ANALİZİ
  void _analyzeWalkingPattern(double magnitude, DateTime now) {
    // 1. Çok yüksek ivme = telefon sallama (filtrele)
    if (magnitude > _maxAcceleration) {
      print('🚫 Çok yüksek ivme - sallama algılandı: ${magnitude.toStringAsFixed(2)}');
      _consecutiveHighReadings++;
      if (_consecutiveHighReadings > 3) {
        _isWalkingPattern = false; // Sallama pattern'i
      }
      return;
    }
    
    // 2. Normal ivme aralığında ise reset
    if (magnitude < _walkingThreshold * 2) {
      _consecutiveHighReadings = 0;
    }
    
    // 3. Yürüme eşiği kontrolü
    if (magnitude < _walkingThreshold) {
      return; // Çok düşük ivme
    }
    
    // 4. Buffer analizi - düzenli pattern aranıyor
    if (_accelerometerBuffer.length >= _patternBufferSize) {
      _isWalkingPattern = _detectWalkingPattern();
    }
    
    // 5. Peak detection (yürüme pattern'i varsa)
    if (_isWalkingPattern && _isPeakDetected(magnitude)) {
      _validateAndCountStep(now);
    }
  }

  /// YÜRÜME PATTERN'İ ALGILA
  bool _detectWalkingPattern() {
    if (_accelerometerBuffer.length < _patternBufferSize) return false;
    
    // Pattern özellikleri
    double mean = _accelerometerBuffer.reduce((a, b) => a + b) / _accelerometerBuffer.length;
    double variance = 0;
    
    for (double value in _accelerometerBuffer) {
      variance += pow(value - mean, 2);
    }
    variance /= _accelerometerBuffer.length;
    double stdDeviation = sqrt(variance);
    
    // Yürüme için ideal değerler
    bool steadyPattern = stdDeviation > 0.8 && stdDeviation < 4.0; // Düzenli salınım
    bool moderateIntensity = mean > 1.5 && mean < 8.0; // Orta yoğunluk
    
    // Frequency analizi (basit)
    int peakCount = 0;
    for (int i = 1; i < _accelerometerBuffer.length - 1; i++) {
      if (_accelerometerBuffer[i] > _accelerometerBuffer[i-1] && 
          _accelerometerBuffer[i] > _accelerometerBuffer[i+1] &&
          _accelerometerBuffer[i] > mean + stdDeviation * 0.5) {
        peakCount++;
      }
    }
    
    bool reasonableFrequency = peakCount >= 2 && peakCount <= 6; // 2-6 peak (1-3 adım)
    
    bool isWalking = steadyPattern && moderateIntensity && reasonableFrequency;
    
    if (isWalking != _isWalkingPattern) {
      print(isWalking ? '🚶‍♂️ Yürüme pattern algılandı' : '⏸️ Yürüme durdu');
    }
    
    return isWalking;
  }

  /// PEAK DETECTION
  bool _isPeakDetected(double magnitude) {
    if (_accelerometerBuffer.length < 3) return false;
    
    double threshold = _walkingThreshold * 1.5;
    
    // Local peak check
    int lastIndex = _accelerometerBuffer.length - 1;
    if (lastIndex >= 2) {
      double prev = _accelerometerBuffer[lastIndex - 1];
      double current = magnitude;
      double prevPrev = _accelerometerBuffer[lastIndex - 2];
      
      return current > prev && prev > prevPrev && current > threshold;
    }
    
    return false;
  }

  /// ADIM DOĞRULAMA VE SAYMA
  void _validateAndCountStep(DateTime now) {
    // Zaman kontrolü
    if (_lastStepTime != null) {
      int timeDiff = now.difference(_lastStepTime!).inMilliseconds;
      
      // Çok hızlı adım (gürültü filtresi)
      if (timeDiff < _minTimeBetweenSteps) {
        return;
      }
      
      // Çok yavaş adım (muhtemelen yürüme bitti)
      if (timeDiff > _maxTimeBetweenSteps) {
        _isWalkingPattern = false;
      }
    }
    
    // Adım sayma şartları karşılanıyor
    if (_isWalkingPattern) {
      _recordStep(now);
    }
  }

  /// ADIM KAYDETME
  void _recordStep(DateTime now) {
    _stepTimestamps.add(now);
    _lastStepTime = now;
    
    // Eski timestamp'leri temizle (son 10 saniye)
    _stepTimestamps.removeWhere((time) => 
        now.difference(time).inSeconds > 10);
    
    _dailySteps++;
    _saveSteps();
    notifyListeners();
    _checkStepAchievements();
    
    print('👣 Adım kaydedildi: $_dailySteps (Pattern: $_isWalkingPattern)');
  }

  /// Adım başarımlarını kontrol et
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

  /// Kayıtlı verileri SharedPreferences'tan yükler.
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
    
    notifyListeners();
  }

  /// Günlük adım sayısını kaydeder.
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

  /// Manuel adım ekleme (test/debug için)
  Future<void> addManualSteps(int steps) async {
    _dailySteps += steps;
    await _saveSteps();
    _checkStepAchievements();
    notifyListeners();
  }

  /// Adım sayacını sıfırla (test için)
  Future<void> resetDailySteps() async {
    _dailySteps = 0;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.remove(_stepsKey + todayKey);
    await _prefs.remove(_initialStepsKey + todayKey);
    _initialStepCount = 0;
    _todayStartSteps = 0;
    notifyListeners();
  }

  /// Tüm verileri zorla kaydet
  Future<void> forceSave() async {
    await _saveSteps();
    await _saveCompletedExercises();
  }

  /// Debug bilgisi
  String getStepCounterStatus() {
    return _useSystemPedometer ? 'Sistem Pedometer' : 'Akıllı Accelerometer';
  }
  
  @override
  void dispose() {
    _stepCountStream?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}