// lib/models/food_model.dart
import 'package:uuid/uuid.dart';

class FoodModel {
  String id;
  String name;
  double calories; // 100g için Enerji (kcal)
  double protein;  // 100g için Protein (g)
  double carbs;    // 100g için Karbonhidrat (g)
  double fat;      // 100g için Yağ (g)
  double? sugar;
  double? fiber;
  double? sodium;
  String category;
  bool isTurkish;

  // YENİ: Porsiyon bilgileri eklendi
  double? servingSizeGrams; // Bir porsiyonun gram karşılığı (örn: 30)
  String? servingUnitName;  // Porsiyonun adı (örn: "ölçek", "adet", "dilim")

  FoodModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sugar,
    this.fiber,
    this.sodium,
    this.category = 'unknown',
    this.isTurkish = false,
    this.servingSizeGrams, // Constructor'a eklendi
    this.servingUnitName,  // Constructor'a eklendi
  });

  // Belirtilen grama göre besin değerlerini hesaplayan yardımcı fonksiyonlar
  double getCaloriesForGrams(double grams) => (calories * grams) / 100;
  double getProteinForGrams(double grams) => (protein * grams) / 100;
  double getCarbsForGrams(double grams) => (carbs * grams) / 100;
  double getFatForGrams(double grams) => (fat * grams) / 100;
  double getSugarForGrams(double grams) => ((sugar ?? 0.0) * grams) / 100;
  double getFiberForGrams(double grams) => ((fiber ?? 0.0) * grams) / 100;
  double getSodiumForGrams(double grams) => ((sodium ?? 0.0) * grams) / 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sugar': sugar,
        'fiber': fiber,
        'sodium': sodium,
        'category': category,
        'isTurkish': isTurkish,
        'servingSizeGrams': servingSizeGrams, // JSON'a eklendi
        'servingUnitName': servingUnitName,   // JSON'a eklendi
      };

  factory FoodModel.fromJson(Map<String, dynamic> json) => FoodModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        calories: json['calories']?.toDouble() ?? 0.0,
        protein: json['protein']?.toDouble() ?? 0.0,
        carbs: json['carbs']?.toDouble() ?? 0.0,
        fat: json['fat']?.toDouble() ?? 0.0,
        sugar: json['sugar']?.toDouble(),
        fiber: json['fiber']?.toDouble(),
        sodium: json['sodium']?.toDouble(),
        category: json['category'] ?? 'unknown',
        isTurkish: json['isTurkish'] ?? false,
        servingSizeGrams: json['servingSizeGrams']?.toDouble(), // JSON'dan okuma eklendi
        servingUnitName: json['servingUnitName'],              // JSON'dan okuma eklendi
      );

  // Edamam API'sinden gelen veriyi parse etmek için
  factory FoodModel.fromJsonEdamam(Map<String, dynamic> json) {
    String foodId =
        json['foodId'] ?? (json['uri'] != null ? json['uri'].split('#').last : '');
    final nutrients = json['nutrients'] as Map<String, dynamic>? ?? {};
    return FoodModel(
      id: foodId,
      name: json['label'] ?? json['foodId'] ?? 'Bilinmeyen Yemek',
      calories: nutrients['ENERC_KCAL']?.toDouble() ?? 0.0,
      protein: nutrients['PROCNT']?.toDouble() ?? 0.0,
      carbs: nutrients['CHOCDF']?.toDouble() ?? 0.0,
      fat: nutrients['FAT']?.toDouble() ?? 0.0,
      sugar: nutrients['SUGAR']?.toDouble(),
      fiber: nutrients['FIBTG']?.toDouble(),
      sodium: nutrients['NA']?.toDouble(),
    );
  }
}

class ConsumedFood {
  final String id;
  String foodId;
  String foodName;
  double grams;
  double totalCalories;
  double totalProtein;
  double totalCarbs;
  double totalFat;
  String mealType;
  DateTime consumedAt;
  double? totalSugar;
  double? totalFiber;
  double? totalSodium;

  ConsumedFood({
    String? id,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealType,
    required this.consumedAt,
    this.totalSugar,
    this.totalFiber,
    this.totalSodium,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'foodName': foodName,
        'grams': grams,
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
        'mealType': mealType,
        'consumedAt': consumedAt.toIso8601String(),
        'totalSugar': totalSugar,
        'totalFiber': totalFiber,
        'totalSodium': totalSodium,
      };

  factory ConsumedFood.fromJson(Map<String, dynamic> json) => ConsumedFood(
        id: json['id'],
        foodId: json['foodId'] ?? '',
        foodName: json['foodName'] ?? '',
        grams: json['grams']?.toDouble() ?? 0.0,
        totalCalories: json['totalCalories']?.toDouble() ?? 0.0,
        totalProtein: json['totalProtein']?.toDouble() ?? 0.0,
        totalCarbs: json['totalCarbs']?.toDouble() ?? 0.0,
        totalFat: json['totalFat']?.toDouble() ?? 0.0,
        mealType: json['mealType'] ?? '',
        consumedAt: DateTime.parse(json['consumedAt']),
        totalSugar: json['totalSugar']?.toDouble(),
        totalFiber: json['totalFiber']?.toDouble(),
        totalSodium: json['totalSodium']?.toDouble(),
      );
}
