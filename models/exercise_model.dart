// lib/models/exercise_model.dart
import 'package:uuid/uuid.dart';

class ExerciseModel {
  String id;
  String name;
  String category;
  double metValue;
  String description;
  String? instructions;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.metValue,
    required this.description,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'metValue': metValue,
        'description': description,
        'instructions': instructions,
      };

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        metValue: json['metValue']?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        instructions: json['instructions'],
      );
}

class CompletedExercise {
  // HATA DÜZELTME: Her tamamlanan egzersizin benzersiz bir ID'si olmalı.
  // Bu, listeden silme gibi işlemleri güvenilir hale getirir.
  final String id;
  String exerciseId;
  String exerciseName;
  String category;
  int sets;
  int reps;
  double? weight;
  int durationMinutes;
  double burnedCalories;
  DateTime completedAt;

  double? distanceKm;
  double? speedKmh;
  double? inclinePercent;

  CompletedExercise({
    String? id, // ID opsiyonel, verilmezse otomatik oluşturulur.
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
    required this.reps,
    this.weight,
    required this.durationMinutes,
    required this.burnedCalories,
    required this.completedAt,
    this.distanceKm,
    this.speedKmh,
    this.inclinePercent,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id, // ID'yi JSON'a ekle
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'category': category,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'durationMinutes': durationMinutes,
        'burnedCalories': burnedCalories,
        'completedAt': completedAt.toIso8601String(),
        'distanceKm': distanceKm,
        'speedKmh': speedKmh,
        'inclinePercent': inclinePercent,
      };

  factory CompletedExercise.fromJson(Map<String, dynamic> json) =>
      CompletedExercise(
        id: json['id'], // ID'yi JSON'dan oku
        exerciseId: json['exerciseId'] ?? '',
        exerciseName: json['exerciseName'] ?? '',
        category: json['category'] ?? '',
        sets: json['sets'] ?? 0,
        reps: json['reps'] ?? 0,
        weight: json['weight']?.toDouble(),
        durationMinutes: json['durationMinutes'] ?? 0,
        burnedCalories: json['burnedCalories']?.toDouble() ?? 0.0,
        completedAt: DateTime.parse(json['completedAt']),
        distanceKm: json['distanceKm']?.toDouble(),
        speedKmh: json['speedKmh']?.toDouble(),
        inclinePercent: json['inclinePercent']?.toDouble(),
      );
}
