// lib/providers/exercise_provider.dart
import 'dart:async';
import 'dart:convert';
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
  int _stepCount = 0;
  double _lastMagnitude = 0;
  bool _isStepDetected = false;
  int _savedStepsToday = 0; // Günün başında storage'dan yüklenen adım sayısı

  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';

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

  /// Cihazın accelerometer sensörünü kullanarak adım sayımı yapar.
  void _initStepCounter() {
    _accelerometerSubscription = userAccelerometerEvents.listen(
      (UserAccelerometerEvent event) {
        _detectStep(event);
      },
      onError: (error) {
        print("Accelerometer hatası: $error");
        _accelerometerSubscription?.cancel();
      },
      cancelOnError: true,
    );
  }

  /// Accelerometer verilerini kullanarak adım algılama algoritması
  void _detectStep(UserAccelerometerEvent event) {
    // Üç eksenin büyüklüğünü hesapla
    double magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
    
    // Basit peak detection algoritması
    const double threshold = 12.0; // Eşik değeri
    
    if (magnitude > threshold && magnitude > _lastMagnitude && !_isStepDetected) {
      _stepCount++;
      _isStepDetected = true;
      
      setState(() {
        _dailySteps = _savedStepsToday + _stepCount;
        _saveSteps();
      });
      
      // Bir sonraki adım için bekleme süresi
      Timer(const Duration(milliseconds: 300), () {
        _isStepDetected = false;
      });
    }
    
    _lastMagnitude = magnitude;
  }

  // Provider içinde state güncellemeleri için yardımcı bir metod
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
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
    
    // Günün başında kayıtlı olan adım sayısını yüklüyoruz.
    _savedStepsToday = _prefs.getInt(_stepsKey + todayKey) ?? 0;
    _dailySteps = _savedStepsToday; // UI'ı başlangıçta bu değerle güncelliyoruz.

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
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}