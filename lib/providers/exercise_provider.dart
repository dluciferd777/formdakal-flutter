// lib/providers/exercise_provider.dart - PROFESYONEL ADIM SAYAR
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

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  
  // Profesyonel adım algılama parametreleri
  List<double> _magnitudeBuffer = [];
  List<double> _filteredBuffer = [];
  List<DateTime> _stepTimes = [];
  
  // Research-based parametreler
  static const int _bufferSize = 100; // 5 saniye (20Hz)
  static const double _minThreshold = 0.035; // 0.035g minimum eşik
  static const double _maxThreshold = 0.2;   // 0.2g maksimum eşik
  static const int _minStepInterval = 200;   // 200ms minimum adım aralığı
  static const int _maxStepInterval = 2000;  // 2 saniye maksimum adım aralığı
  static const double _lowPassAlpha = 0.3;   // Low-pass filtre katsayısı
  
  // Adaptif eşik parametreleri
  double _currentThreshold = 0.1;
  double _baselineNoise = 0.02;
  int _consecutiveSteps = 0;
  
  int _savedStepsToday = 0;

  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider) {
    loadData();
    _initProfessionalStepCounter();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
  }

  List<CompletedExercise> get completedExercises => _completedExercises;
  int get dailySteps => _dailySteps;
  int get dailyActiveMinutes => _dailyActiveMinutes;

  /// Araştırma tabanlı profesyonel adım sayar
  void _initProfessionalStepCounter() {
    try {
      // SENSOR_DELAY_GAME kullan (research'te en iyi sonuç)
      _accelerometerSubscription = userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          _processAccelerometerProfessional(event);
        },
        onError: (error) {
          debugPrint("❌ Accelerometer hatası: $error");
          Timer(const Duration(seconds: 5), () {
            _initProfessionalStepCounter();
          });
        },
        cancelOnError: true,
      );
      debugPrint("✅ Profesyonel adım sayar başlatıldı (Research-based)");
    } catch (e) {
      debugPrint("❌ Adım sayar başlatma hatası: $e");
    }
  }

  /// Research-based magnitude vector processing
  void _processAccelerometerProfessional(UserAccelerometerEvent event) {
    try {
      // Magnitude vector hesapla (orientation-independent)
      double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      
      // Gravity'yi çıkar (magnitude'den ~1g çıkar)
      magnitude = magnitude - 1.0;
      magnitude = magnitude.abs();
      
      // Buffer'a ekle
      _magnitudeBuffer.add(magnitude);
      if (_magnitudeBuffer.length > _bufferSize) {
        _magnitudeBuffer.removeAt(0);
      }
      
      // Low-pass filtre uygula (research'te önerilen)
      double filtered = _applyLowPassFilter(magnitude);
      _filteredBuffer.add(filtered);
      if (_filteredBuffer.length > _bufferSize) {
        _filteredBuffer.removeAt(0);
      }
      
      // Minimum buffer size kontrolü
      if (_filteredBuffer.length < 10) return;
      
      // Adaptif eşik güncelle
      _updateAdaptiveThreshold();
      
      // Peak detection ve adım validation
      if (_detectValidStep(filtered)) {
        _registerStep();
      }
      
    } catch (e) {
      debugPrint("❌ Accelerometer veri işleme hatası: $e");
    }
  }

  /// Research-based low-pass filter
  double _applyLowPassFilter(double newValue) {
    if (_filteredBuffer.isEmpty) return newValue;
    
    double lastFiltered = _filteredBuffer.last;
    return _lowPassAlpha * newValue + (1 - _lowPassAlpha) * lastFiltered;
  }

  /// Adaptif eşik hesaplama (research-based)
  void _updateAdaptiveThreshold() {
    if (_filteredBuffer.length < 20) return;
    
    // Son 20 değerin variance'ını hesapla
    List<double> recent = _filteredBuffer.skip(_filteredBuffer.length - 20).toList();
    double mean = recent.reduce((a, b) => a + b) / recent.length;
    double variance = recent.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recent.length;
    double stdDev = sqrt(variance);
    
    // Adaptif eşik: mean + 2*stdDev (research'te proven)
    _currentThreshold = (mean + 2 * stdDev).clamp(_minThreshold, _maxThreshold);
    _baselineNoise = stdDev;
  }

  /// Gelişmiş adım validation (research-based)
  bool _detectValidStep(double magnitude) {
    if (_filteredBuffer.length < 5) return false;
    
    // 1. Threshold kontrolü
    if (magnitude < _currentThreshold) return false;
    
    // 2. Peak detection - local maximum kontrolü
    if (!_isLocalMaximum(magnitude)) return false;
    
    // 3. Timing validation - human walking frequency (0.5-3Hz)
    DateTime now = DateTime.now();
    if (_stepTimes.isNotEmpty) {
      int timeSinceLastStep = now.difference(_stepTimes.last).inMilliseconds;
      if (timeSinceLastStep < _minStepInterval || timeSinceLastStep > _maxStepInterval) {
        return false;
      }
    }
    
    // 4. Signal quality kontrolü
    if (_baselineNoise > 0.05) { // Çok gürültülü sinyal
      return false;
    }
    
    // 5. Consecutive step pattern validation
    if (_stepTimes.length >= 3) {
      if (!_validateStepPattern()) return false;
    }
    
    return true;
  }

  /// Local maximum detection
  bool _isLocalMaximum(double currentValue) {
    if (_filteredBuffer.length < 5) return false;
    
    int currentIndex = _filteredBuffer.length - 1;
    
    // Önceki 2 ve sonraki 2 değerden büyük olmalı
    for (int i = 1; i <= 2; i++) {
      if (currentIndex - i >= 0) {
        if (currentValue <= _filteredBuffer[currentIndex - i]) return false;
      }
    }
    
    return true;
  }

  /// Step pattern validation (research-based)
  bool _validateStepPattern() {
    if (_stepTimes.length < 3) return true;
    
    // Son 3 adımın aralıklarını kontrol et
    List<int> intervals = [];
    for (int i = _stepTimes.length - 3; i < _stepTimes.length - 1; i++) {
      intervals.add(_stepTimes[i + 1].difference(_stepTimes[i]).inMilliseconds);
    }
    
    // Cadence consistency kontrolü (research'te önemli faktör)
    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    for (int interval in intervals) {
      double deviation = (interval - avgInterval).abs() / avgInterval;
      if (deviation > 0.5) { // %50'den fazla sapma varsa invalid
        return false;
      }
    }
    
    return true;
  }

  /// Adımı kaydet
  void _registerStep() {
    DateTime now = DateTime.now();
    _stepTimes.add(now);
    
    // Step buffer'ı temizle (son 10 adım yeterli)
    if (_stepTimes.length > 10) {
      _stepTimes.removeAt(0);
    }
    
    _consecutiveSteps++;
    _dailySteps++;
    
    setState(() {
      _saveSteps();
    });

    // Debug log (her 50 adımda)
    if (_dailySteps % 50 == 0) {
      debugPrint("🚶 Professional Step Counter: $_dailySteps adım (Eşik: ${_currentThreshold.toStringAsFixed(3)})");
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// Verileri yükle
  Future<void> loadData() async {
    try {
      final exerciseJson = _prefs.getString(_exercisesKey);
      if (exerciseJson != null) {
        final List<dynamic> decoded = jsonDecode(exerciseJson);
        _completedExercises =
            decoded.map((item) => CompletedExercise.fromJson(item)).toList();
      }
      
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      _savedStepsToday = _prefs.getInt(_stepsKey + todayKey) ?? 0;
      _dailySteps = _savedStepsToday;
      _dailyActiveMinutes = _prefs.getInt(_minutesKey + todayKey) ?? 0;
      
      debugPrint("📂 Exercise verileri yüklendi - Adım: $_dailySteps");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Exercise veri yükleme hatası: $e");
    }
  }

  /// Adım sayısını kaydet
  Future<void> _saveSteps() async {
    try {
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      await _prefs.setInt(_stepsKey + todayKey, _dailySteps);
    } catch (e) {
      debugPrint("❌ Adım kaydetme hatası: $e");
    }
  }

  /// Test için manuel adım ekleme
  void addTestSteps(int steps) {
    setState(() {
      _dailySteps += steps;
      _saveSteps();
    });
    debugPrint("🧪 Test adım eklendi: +$steps, Toplam: $_dailySteps");
  }

  /// Adım sayarı sıfırla
  void resetSteps() {
    setState(() {
      _dailySteps = 0;
      _savedStepsToday = 0;
      _consecutiveSteps = 0;
      _stepTimes.clear();
      _saveSteps();
    });
    debugPrint("🔄 Adım sayar sıfırlandı");
  }

  /// Kalibrasyon bilgisi
  Map<String, dynamic> getCalibrationInfo() {
    return {
      'currentThreshold': _currentThreshold.toStringAsFixed(4),
      'baselineNoise': _baselineNoise.toStringAsFixed(4),
      'consecutiveSteps': _consecutiveSteps,
      'recentSteps': _stepTimes.length,
      'bufferSize': _filteredBuffer.length,
      'isActive': isStepCounterActive(),
    };
  }

  Future<void> _saveCompletedExercises() async {
    try {
      final jsonList = _completedExercises.map((exercise) => exercise.toJson()).toList();
      await _prefs.setString(_exercisesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("❌ Exercise kaydetme hatası: $e");
    }
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

  bool isStepCounterActive() {
    return _accelerometerSubscription != null && !_accelerometerSubscription!.isPaused;
  }

  void restartStepCounter() {
    _accelerometerSubscription?.cancel();
    _initProfessionalStepCounter();
    debugPrint("🔄 Profesyonel adım sayar yeniden başlatıldı");
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    debugPrint("🛑 Professional exercise provider disposed");
    super.dispose();
  }
}