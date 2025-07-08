// lib/screens/workout_plan_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/exercises_data.dart';
import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../providers/exercise_provider.dart';
import '../providers/user_provider.dart';
import '../services/calorie_service.dart';
import '../utils/colors.dart';

class WorkoutPlanDetailsScreen extends StatelessWidget {
  final WorkoutPlanModel plan;

  const WorkoutPlanDetailsScreen({super.key, required this.plan});

  ExerciseModel? _getExerciseById(String id) {
    try {
      return ExercisesData.getFullExerciseListAsMap()
          .values
          .expand((e) => e)
          .firstWhere((ex) => ex.id == id);
    } catch (e) {
      return null;
    }
  }

  void _startWorkoutForDay(BuildContext context, List<ExerciseInPlan> exercises) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen önce profil bilgilerinizi girin.')));
      return;
    }

    int exercisesAdded = 0;
    for (var exerciseInPlan in exercises) {
      final exerciseDetails = _getExerciseById(exerciseInPlan.exerciseId);
      if (exerciseDetails == null) continue;

      CompletedExercise? completedExercise;

      if (exerciseDetails.category == 'cardio') {
        final duration = int.tryParse(exerciseInPlan.duration ?? '0') ?? 0;
        if (duration > 0) {
          final burnedCalories = CalorieService.calculateCardioCalories(
            exerciseType: exerciseDetails.id,
            userWeight: user.weight,
            durationMinutes: duration,
          );
          completedExercise = CompletedExercise(
            exerciseId: exerciseDetails.id, exerciseName: exerciseDetails.name, category: exerciseDetails.category,
            sets: 0, reps: 0, durationMinutes: duration, burnedCalories: burnedCalories, completedAt: DateTime.now());
        }
      } else {
        final sets = int.tryParse(exerciseInPlan.sets ?? '0') ?? 0;
        final reps = int.tryParse((exerciseInPlan.reps ?? '0').split('-').first) ?? 0;
        final weight = double.tryParse(exerciseInPlan.weight ?? '0') ?? 0.0;
        if (sets > 0 && reps > 0) {
          final burnedCalories = CalorieService.calculateEnhancedExerciseCalories(
            metValue: exerciseDetails.metValue, userWeight: user.weight, sets: sets, reps: reps, weightKg: weight);
          completedExercise = CompletedExercise(
            exerciseId: exerciseDetails.id, exerciseName: exerciseDetails.name, category: exerciseDetails.category,
            sets: sets, reps: reps, weight: weight > 0 ? weight : null,
            durationMinutes: CalorieService.estimateExerciseDuration(sets, reps),
            burnedCalories: burnedCalories, completedAt: DateTime.now());
        }
      }
      
      if (completedExercise != null) {
        exerciseProvider.addCompletedExercise(completedExercise);
        exercisesAdded++;
      }
    }
    
    if (exercisesAdded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$exercisesAdded egzersiz günlüğünüze eklendi!'),
          backgroundColor: AppColors.success));
      Navigator.pop(context); // Detay ekranını kapat
    }
  }
  
  String _buildPlanExerciseDetails(ExerciseInPlan exercise) {
    if (exercise.duration != null && exercise.duration!.isNotEmpty) {
      return '${exercise.duration} dk';
    } else {
      String details = '${exercise.sets ?? "0"}×${exercise.reps ?? "0"}';
      if (exercise.weight != null && exercise.weight!.isNotEmpty) {
        details += ' @ ${exercise.weight} kg';
      }
      return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutDays = plan.weeklySchedule.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    workoutDays.sort((a, b) => a.key.compareTo(b.key));

    return DefaultTabController(
      length: workoutDays.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plan.name, style: const TextStyle(fontSize: 20)),
          bottom: TabBar(
            isScrollable: true,
            tabs: workoutDays.map((dayEntry) => Tab(text: '${dayEntry.key}. GÜN')).toList(),
          ),
        ),
        body: SafeArea( // Burası eklendi
          child: TabBarView(
            children: workoutDays.map((dayEntry) {
              final exercises = dayEntry.value;
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exerciseInPlan = exercises[index];
                        final exerciseDetails = _getExerciseById(exerciseInPlan.exerciseId);
                        if (exerciseDetails == null) {
                          return Card(child: ListTile(title: Text('${exerciseInPlan.exerciseId} bulunamadı.')));
                        }
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center, color: AppColors.primaryGreen),
                            title: Text(exerciseDetails.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(_buildPlanExerciseDetails(exerciseInPlan)),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(exerciseDetails.name),
                                  content: Text(exerciseDetails.description),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
                                )
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _startWorkoutForDay(context, exercises),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bu Antrenmanı Başlat'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
