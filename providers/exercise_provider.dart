// lib/providers/exercise_provider.dart - PROFESYONEL ADIM SAYAR
import 'dart:async';
import 'dart:convert';
// import 'dart:math'; // Bu satır kaldırıldı
import 'package:flutter/material.dart';
import 'package:formdakal/providers/user_provider.dart';
// import 'package:sensors_plus/sensors_plus.dart'; // Accelerometer için kaldırıldı
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../services/calorie_service.dart';
import '../services/native_step_counter_service.dart'; // NativeStepCounterService eklendi
import 'achievement_provider.dart';

class ExerciseProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late AchievementProvider _achievementProvider;
  late UserProvider _userProvider;
  late NativeStepCounterService _nativeStepCounterService; // NativeStepCounterService eklendi

  List<CompletedExercise> _completedExercises = [];

  static const _exercisesKey = 'completed_exercises';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider, this._nativeStepCounterService) {
    loadData();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider, NativeStepCounterService nativeStepCounterService) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
    _nativeStepCounterService = nativeStepCounterService; // Bağımlılık güncellendi
  }

  List<CompletedExercise> get completedExercises => _completedExercises;

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
      
      debugPrint("📂 Exercise verileri yüklendi"); // Adım bilgisi kaldırıldı
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Exercise veri yükleme hatası: $e");
    }
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
    
    // Adım verisini NativeStepCounterService'ten al
    final int dailySteps = _nativeStepCounterService.dailySteps;
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final dateKey = date.toIso8601String().substring(0, 10);

    // Sadece bugünün adımlarını kullan (geçmiş adımlar için NativeStepCounterService'in geçmiş veriyi sağlaması gerekir)
    if (dateKey == todayKey && dailySteps > 0 && userWeight > 0) {
      stepCalories = CalorieService.calculateStepCalories(dailySteps, userWeight);
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
    debugPrint("🛑 Professional exercise provider disposed");
    super.dispose();
  }
}
