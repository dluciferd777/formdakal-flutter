// lib/providers/workout_plan_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/exercises_data.dart';
import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../services/calorie_service.dart';
import 'achievement_provider.dart';
import 'exercise_provider.dart';
import 'user_provider.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late AchievementProvider _achievementProvider;
  late UserProvider _userProvider;
  late ExerciseProvider _exerciseProvider;

  WorkoutPlanModel? myPushPlan;
  WorkoutPlanModel? myPullPlan;
  WorkoutPlanModel? myLegPlan;

  static const _pushKey = 'custom_push_plan';
  static const _pullKey = 'custom_pull_plan';
  static const _legKey = 'custom_leg_plan';

  WorkoutPlanProvider(this._prefs, this._achievementProvider, this._userProvider, this._exerciseProvider) {
    loadCustomPlans();
  }

  void updateDependencies(
    AchievementProvider achProvider,
    UserProvider usrProvider,
    ExerciseProvider exProvider,
  ) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
    _exerciseProvider = exProvider;
  }

  Future<void> addWorkoutDayToLog(BuildContext context, WorkoutPlanModel plan, int dayKey) async {
    final exercisesForDay = plan.weeklySchedule[dayKey];
    if (exercisesForDay == null || exercisesForDay.isEmpty) return;

    final user = _userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce profil bilgilerinizi girin.')));
      return;
    }

    for (var exerciseInPlan in exercisesForDay) {
      final exerciseDetails = ExercisesData.getFullExerciseListAsMap()
          .values
          .expand((e) => e)
          .firstWhere((ex) => ex.id == exerciseInPlan.exerciseId);

      CompletedExercise? completedExercise;

      if (exerciseDetails.category == 'cardio') {
        final duration = int.tryParse(exerciseInPlan.duration ?? '0') ?? 0;
        if (duration > 0) {
          final distance = double.tryParse(exerciseInPlan.distance ?? '0') ?? 0.0;
          final incline = double.tryParse(exerciseInPlan.incline ?? '0') ?? 0.0;
          final speed = distance > 0 ? (distance / (duration / 60.0)) : 0.0;
          final burnedCalories = CalorieService.calculateCardioCalories(
            exerciseType: exerciseDetails.id,
            userWeight: user.weight,
            durationMinutes: duration,
            speed: speed > 0 ? speed : null,
            incline: incline > 0 ? incline : null,
          );
          completedExercise = CompletedExercise(
            exerciseId: exerciseDetails.id,
            exerciseName: exerciseDetails.name,
            category: exerciseDetails.category,
            sets: 0,
            reps: 0,
            durationMinutes: duration,
            burnedCalories: burnedCalories,
            completedAt: DateTime.now(),
            distanceKm: distance > 0 ? distance : null,
            speedKmh: speed > 0 ? speed : null,
            inclinePercent: incline > 0 ? incline : null,
          );
        }
      } else {
        final sets = int.tryParse(exerciseInPlan.sets ?? '0') ?? 0;
        final reps =
            int.tryParse((exerciseInPlan.reps ?? '0').split('-').first) ?? 0;
        final weight = double.tryParse(exerciseInPlan.weight ?? '0') ?? 0.0;
        if (sets > 0 && reps > 0) {
          final burnedCalories =
              CalorieService.calculateEnhancedExerciseCalories(
            metValue: exerciseDetails.metValue,
            userWeight: user.weight,
            sets: sets,
            reps: reps,
            weightKg: weight,
          );
          completedExercise = CompletedExercise(
              exerciseId: exerciseDetails.id,
              exerciseName: exerciseDetails.name,
              category: exerciseDetails.category,
              sets: sets,
              reps: reps,
              weight: weight > 0 ? weight : null,
              durationMinutes: CalorieService.estimateExerciseDuration(sets, reps),
              burnedCalories: burnedCalories,
              completedAt: DateTime.now());
        }
      }
      if (completedExercise != null) {
        _exerciseProvider.addCompletedExercise(completedExercise);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Antrenman, fitness günlüğünüze eklendi!'),
        backgroundColor: AppColors.success));
    Navigator.pushNamed(context, '/fitness');
  }

  void _checkPlanAchievements() {
    if (myPushPlan != null || myPullPlan != null || myLegPlan != null) {
      _achievementProvider.unlockAchievement('create_first_plan');
    }
  }

  Future<void> saveCustomPlan(WorkoutPlanModel plan, String planType) async {
    bool wasNullBefore = false;
    switch (planType) {
      case 'push':
        wasNullBefore = myPushPlan == null;
        myPushPlan = plan;
        await _savePlanToKey(_pushKey, plan);
        break;
      case 'pull':
        wasNullBefore = myPullPlan == null;
        myPullPlan = plan;
        await _savePlanToKey(_pullKey, plan);
        break;
      case 'leg':
        wasNullBefore = myLegPlan == null;
        myLegPlan = plan;
        await _savePlanToKey(_legKey, plan);
        break;
    }
    if (wasNullBefore) {
      _checkPlanAchievements();
    }
    notifyListeners();
  }

  Future<void> loadCustomPlans() async {
    myPushPlan = await _loadPlanFromKey(_pushKey);
    myPullPlan = await _loadPlanFromKey(_pullKey);
    myLegPlan = await _loadPlanFromKey(_legKey);
    notifyListeners();
  }

  Future<WorkoutPlanModel?> _loadPlanFromKey(String key) async {
    final dataString = _prefs.getString(key);
    if (dataString == null) return null;
    return WorkoutPlanModel.fromJson(jsonDecode(dataString));
  }

  Future<void> _savePlanToKey(String key, WorkoutPlanModel? plan) async {
    if (plan == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, jsonEncode(plan.toJson()));
    }
  }
}
