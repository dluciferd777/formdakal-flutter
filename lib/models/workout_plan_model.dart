// lib/models/workout_plan_model.dart

class ExerciseInPlan {
  final String exerciseId;
  String? sets;
  String? reps;
  String? weight;
  String? duration;
  String? distance;
  String? incline;

  ExerciseInPlan({
    required this.exerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.duration,
    this.distance,
    this.incline,
  });

  // DÜZELTME: Kaydetme/okuma için toJson ve fromJson eklendi
  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'reps': reps,
    'weight': weight,
    'duration': duration,
    'distance': distance,
    'incline': incline,
  };

  factory ExerciseInPlan.fromJson(Map<String, dynamic> json) => ExerciseInPlan(
    exerciseId: json['exerciseId'],
    sets: json['sets'],
    reps: json['reps'],
    weight: json['weight'],
    duration: json['duration'],
    distance: json['distance'],
    incline: json['incline'],
  );
}

class WorkoutPlanModel {
  final String id;
  final String name;
  final String description;
  final int durationWeeks;
  final Map<int, List<ExerciseInPlan>> weeklySchedule;

  WorkoutPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.weeklySchedule,
  });

  // DÜZELTME: Kaydetme/okuma için toJson ve fromJson eklendi
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'durationWeeks': durationWeeks,
    'weeklySchedule': weeklySchedule.map(
      (key, value) => MapEntry(key.toString(), value.map((e) => e.toJson()).toList()),
    ),
  };

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    var scheduleFromJson = json['weeklySchedule'] as Map<String, dynamic>;
    Map<int, List<ExerciseInPlan>> schedule = scheduleFromJson.map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as List).map((e) => ExerciseInPlan.fromJson(e)).toList(),
      ),
    );
    return WorkoutPlanModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      durationWeeks: json['durationWeeks'],
      weeklySchedule: schedule,
    );
  }
}