// lib/providers/exercise_provider.dart - DEBUG VERSİYONU
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
  
  // BASITLEŞTIRILMIŞ ADIM SAYACI
  int _initialStepCount = 0;
  int _todayStartSteps = 0;
  bool _useSystemPedometer = true;
  String _debugStatus = 'Başlatılıyor...';
  
  // ACCELEROMETER BACKUP
  double _lastMagnitude = 0;
  DateTime? _lastStepTime;
  int _accelerometerSteps = 0;
  
  // AYARLAR - DAHA KOLAY DETECTION
  static const double _stepThreshold = 12.0; // Daha düşük eşik
  static const int _minStepInterval = 250; // Daha hızlı adım
  static const int _maxStepInterval = 2000; // Maksimum adım aralığı

  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';
  static const _initialStepsKey = 'initial_steps_';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider) {
    loadData();
    _initStepCounter();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
  }

  List<CompletedExercise> get completedExercises => _completedExercises;
  int get dailySteps => _dailySteps;
  int get dailyActiveMinutes => _dailyActiveMinutes;
  String get debugStatus => _debugStatus; // Debug bilgisi için

  /// ADIM SAYACI BAŞLATMA - DEBUG İLE
  void _initStepCounter() async {
    print('🚀 Adım sayacı başlatılıyor...');
    _debugStatus = 'Sistem pedometer deneniyor...';
    
    try {
      // Önce sistem pedometer'ı dene
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onSystemStepCount,
        onError: (error) {
          print('❌ Sistem pedometer HATASI: $error');
          _debugStatus = 'Sistem pedometer hatası: $error';
          _useSystemPedometer = false;
          _startAccelerometer();
        },
        cancelOnError: false,
      );
      
      // 5 saniye bekle, sistem pedometer çalışıyor mu?
      Timer(Duration(seconds: 5), () {
        if (_useSystemPedometer && _initialStepCount == 0) {
          print('⚠️ Sistem pedometer 5 saniyede veri göndermedi, accelerometer\'a geçiliyor');
          _debugStatus = 'Sistem pedometer sessiz, accelerometer aktif';
          _useSystemPedometer = false;
          _startAccelerometer();
        }
      });
      
    } catch (e) {
      print('❌ Pedometer başlatılamadı: $e');
      _debugStatus = 'Pedometer hatası: $e';
      _useSystemPedometer = false;
      _startAccelerometer();
    }
  }

  /// Sistem Pedometer Verisi
  void _onSystemStepCount(StepCount event) async {
    print('📱 Sistem pedometer verisi: ${event.steps}');
    _debugStatus = 'Sistem pedometer aktif: ${event.steps} adım';
    
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    
    // İlk veri geldiğinde başlangıç ayarla
    if (_initialStepCount == 0) {
      _initialStepCount = event.steps;
      _todayStartSteps = _prefs.getInt(_initialStepsKey + todayKey) ?? event.steps;
      
      // Yeni güne geçiş kontrolü
      final savedDate = _prefs.getString('last_step_date') ?? '';
      if (savedDate != todayKey) {
        print('📅 Yeni gün başlıyor, adım sayacı sıfırlanıyor');
        _todayStartSteps = event.steps;
        await _prefs.setInt(_initialStepsKey + todayKey, event.steps);
        await _prefs.setString('last_step_date', todayKey);
      }
      
      print('🎯 Başlangıç adım sayısı: $_todayStartSteps');
    }

    // Bugünkü adım sayısını hesapla
    final todaySteps = event.steps - _todayStartSteps;
    
    if (todaySteps >= 0) {
      _dailySteps = todaySteps;
      await _saveSteps();
      notifyListeners();
      _checkStepAchievements();
      print('✅ Güncel adım sayısı: $_dailySteps');
    } else {
      print('⚠️ Negatif adım sayısı: $todaySteps');
    }
  }

  /// Accelerometer Başlat (Fallback)
  void _startAccelerometer() {
    print('🧠 Accelerometer başlatılıyor...');
    _debugStatus = 'Accelerometer aktif';
    
    _accelerometerSubscription = userAccelerometerEvents.listen(
      _onAccelerometerEvent,
      onError: (error) {
        print('❌ Accelerometer hatası: $error');
        _debugStatus = 'Accelerometer hatası: $error';
      },
      cancelOnError: false,
    );
  }

  /// Accelerometer Verisi - BASİT ADIM ALGILIYOR
  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();
    
    // Debug: Her 50 accelerometer okuma için bir log
    if (_accelerometerSteps % 50 == 0) {
      print('📊 Accelerometer: ${magnitude.toStringAsFixed(2)} (Eşik: $_stepThreshold)');
    }
    
    // Basit peak detection
    if (magnitude > _stepThreshold && 
        magnitude > _lastMagnitude && 
        (_lastStepTime == null || now.difference(_lastStepTime!).inMilliseconds > _minStepInterval)) {
      
      _accelerometerSteps++;
      _lastStepTime = now;
      _dailySteps++;
      
      print('👣 Accelerometer adım: $_dailySteps (Magnitude: ${magnitude.toStringAsFixed(2)})');
      _debugStatus = 'Accelerometer: $_dailySteps adım';
      
      _saveSteps();
      notifyListeners();
      _checkStepAchievements();
    }
    
    _lastMagnitude = magnitude;
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
    
    print('📂 Yüklenen günlük adım: $_dailySteps');
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
    print('➕ Manuel adım eklendi: +$steps (Toplam: $_dailySteps)');
  }

  /// Adım sayacını sıfırla (test için)
  Future<void> resetDailySteps() async {
    _dailySteps = 0;
    _accelerometerSteps = 0;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.remove(_stepsKey + todayKey);
    await _prefs.remove(_initialStepsKey + todayKey);
    _initialStepCount = 0;
    _todayStartSteps = 0;
    notifyListeners();
    print('🔄 Adım sayacı sıfırlandı');
  }

  /// Tüm verileri zorla kaydet
  Future<void> forceSave() async {
    await _saveSteps();
    await _saveCompletedExercises();
  }

  /// Debug bilgisi
  String getStepCounterStatus() {
    String status = _useSystemPedometer ? 'Sistem Pedometer' : 'Accelerometer';
    return '$status | $_debugStatus';
  }

  /// DEBUG TEST FONKSİYONU
  void debugStepCounter() {
    print('🐛 === DEBUG BİLGİLERİ ===');
    print('Sistem Pedometer: $_useSystemPedometer');
    print('Debug Status: $_debugStatus');
    print('Günlük Adım: $_dailySteps');
    print('Accelerometer Adım: $_accelerometerSteps');
    print('Başlangıç Adım: $_initialStepCount');
    print('Bugün Başlangıç: $_todayStartSteps');
    print('Son Adım Zamanı: $_lastStepTime');
    print('=========================');
  }
  
  @override
  void dispose() {
    _stepCountStream?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}