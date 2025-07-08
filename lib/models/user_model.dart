// lib/models/user_model.dart
import '../services/calorie_service.dart';

class UserModel {
  String name;
  int age;
  double height;
  double weight;
  String gender;
  String? profileImagePath;
  
  // Opsiyonel Vücut Analizi Alanları
  double? bodyFatPercentage;
  double? musclePercentage;
  double? visceralFat;
  double? waterPercentage;
  int? metabolicAge;
  // DÜZELTME: İsteğiniz üzerine 'kemik oranı' alanı eklendi.
  double? bonePercentage; 

  String activityLevel;
  String goal;
  int weeklyWorkoutDays;
  
  Map<String, double> dailyWaterIntake;
  
  int dailyStepGoal;
  int dailyMinuteGoal;

  UserModel({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    this.profileImagePath,
    this.bodyFatPercentage,
    this.musclePercentage,
    this.visceralFat,
    this.waterPercentage,
    this.metabolicAge,
    this.bonePercentage, // Constructor'a eklendi
    this.activityLevel = 'moderately_active',
    this.goal = 'maintain',
    this.weeklyWorkoutDays = 3,
    this.dailyStepGoal = 6000,
    this.dailyMinuteGoal = 60,
    Map<String, double>? dailyWaterIntake,
  }) : dailyWaterIntake = dailyWaterIntake ?? {};

  double get bmi => CalorieService.calculateBMI(weight, height);
  
  double get bmr {
    return CalorieService.calculateBMR(
      gender: gender, weight: weight, height: height, age: age, bodyFatPercentage: bodyFatPercentage,
    );
  }
  
  double get dailyCalorieNeeds {
    return CalorieService.calculateDailyCalorieNeeds(
      gender: gender, weight: weight, height: height, age: age, activityLevel: activityLevel, goal: goal, bodyFatPercentage: bodyFatPercentage,
    );
  }

  double get dailyProteinGoal => CalorieService.calculateDailyProteinNeeds(weight: weight, activityLevel: activityLevel, goal: goal);
  double get dailyFatGoal => CalorieService.calculateDailyFatNeeds(dailyCalorieNeeds: dailyCalorieNeeds);
  double get dailyCarbGoal => CalorieService.calculateDailyCarbNeeds(dailyCalorieNeeds: dailyCalorieNeeds, proteinGrams: dailyProteinGoal, fatGrams: dailyFatGoal);
  
  Map<String, dynamic> toJson() => {
        'name': name, 'age': age, 'height': height, 'weight': weight, 'gender': gender,
        'profileImagePath': profileImagePath, 'bodyFatPercentage': bodyFatPercentage,
        'musclePercentage': musclePercentage, 'visceralFat': visceralFat,
        'waterPercentage': waterPercentage, 'metabolicAge': metabolicAge,
        'bonePercentage': bonePercentage, // JSON'a eklendi
        'activityLevel': activityLevel, 'goal': goal, 'weeklyWorkoutDays': weeklyWorkoutDays,
        'dailyStepGoal': dailyStepGoal, 'dailyMinuteGoal': dailyMinuteGoal,
        'dailyWaterIntake': dailyWaterIntake,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        height: json['height']?.toDouble() ?? 0.0,
        weight: json['weight']?.toDouble() ?? 0.0,
        gender: json['gender'] ?? 'male',
        profileImagePath: json['profileImagePath'],
        bodyFatPercentage: json['bodyFatPercentage']?.toDouble(),
        musclePercentage: json['musclePercentage']?.toDouble(),
        visceralFat: json['visceralFat']?.toDouble(),
        waterPercentage: json['waterPercentage']?.toDouble(),
        metabolicAge: json['metabolicAge'],
        bonePercentage: json['bonePercentage']?.toDouble(), // JSON'dan okunacak şekilde eklendi
        activityLevel: json['activityLevel'] ?? 'moderately_active',
        goal: json['goal'] ?? 'maintain',
        weeklyWorkoutDays: json['weeklyWorkoutDays'] ?? 3,
        dailyStepGoal: json['dailyStepGoal'] ?? 6000,
        dailyMinuteGoal: json['dailyMinuteGoal'] ?? 60,
        dailyWaterIntake: (json['dailyWaterIntake'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value.toDouble())),
      );
}
