// lib/providers/food_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';
import 'achievement_provider.dart';

class FoodProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  // HATA DÜZELTME: Provider'lar artık birbirlerine BuildContext üzerinden değil,
  // doğrudan bağımlılık olarak bağlanıyor.
  late AchievementProvider _achievementProvider;

  List<ConsumedFood> _consumedFoods = [];
  List<String> _searchHistory = [];

  static const _consumedFoodsKey = 'consumed_foods';
  static const _searchHistoryKey = 'search_history';

  // HATA DÜZELTME: Constructor artık BuildContext almıyor.
  FoodProvider(this._prefs, this._achievementProvider) {
    loadData();
  }

  // DÜZELTME: main.dart'taki ChangeNotifierProxyProvider'ın çalışabilmesi için
  // bağımlılıkları güncelleyen bir metod eklendi.
  void updateDependencies(AchievementProvider achievementProvider) {
    _achievementProvider = achievementProvider;
  }

  List<ConsumedFood> get consumedFoods => _consumedFoods;
  List<String> get searchHistory => _searchHistory;

  Future<void> loadData() async {
    final consumedJson = _prefs.getString(_consumedFoodsKey);
    if (consumedJson != null) {
      _consumedFoods = (jsonDecode(consumedJson) as List)
          .map((item) => ConsumedFood.fromJson(item))
          .toList();
    }
    _searchHistory = _prefs.getStringList(_searchHistoryKey) ?? [];
    notifyListeners();
  }

  Future<void> _saveConsumedFoods() async {
    final jsonList =
        _consumedFoods.map((food) => food.toJson()).toList();
    await _prefs.setString(_consumedFoodsKey, jsonEncode(jsonList));
  }

  Future<void> addConsumedFood(ConsumedFood food) async {
    _consumedFoods.add(food);
    await _saveConsumedFoods();
    _checkFoodAchievements();
    notifyListeners();
  }

  // DÜZELTME: Fonksiyonun içi dolduruldu.
  Future<void> removeConsumedFood(String consumedFoodId) async {
    _consumedFoods.removeWhere((food) => food.id == consumedFoodId);
    await _saveConsumedFoods();
    notifyListeners();
  }

  void _checkFoodAchievements() {
    // HATA DÜZELTME: Artık Provider.of(context) kullanılmıyor.
    // Bağımlılık olarak enjekte edilen _achievementProvider kullanılıyor.
    if (_consumedFoods.length == 1) {
      _achievementProvider.unlockAchievement('first_meal');
    }
  }

  // DÜZELTME: Fonksiyonun içi dolduruldu.
  Future<void> addToSearchHistory(String query) async {
    _searchHistory.remove(query); // Varsa eskisini sil
    _searchHistory.insert(0, query); // Başa ekle
    if (_searchHistory.length > 10) {
      // Son arama listesini 10 ile sınırla
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await _prefs.setStringList(_searchHistoryKey, _searchHistory);
    notifyListeners();
  }

  // DÜZELTME: Belirtilen tarihe göre filtreleme yapan yardımcı fonksiyon
  Iterable<ConsumedFood> _getFoodsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _consumedFoods.where((food) =>
        food.consumedAt.isAfter(startOfDay) &&
        food.consumedAt.isBefore(endOfDay));
  }

  // DÜZELTME: Fonksiyonların içi dolduruldu.
  double getDailyCalories(DateTime date) {
    return _getFoodsForDate(date)
        .fold(0.0, (sum, item) => sum + item.totalCalories);
  }

  double getDailyProtein(DateTime date) {
    return _getFoodsForDate(date)
        .fold(0.0, (sum, item) => sum + item.totalProtein);
  }

  double getDailyCarbs(DateTime date) {
    return _getFoodsForDate(date)
        .fold(0.0, (sum, item) => sum + item.totalCarbs);
  }

  double getDailyFat(DateTime date) {
    return _getFoodsForDate(date).fold(0.0, (sum, item) => sum + item.totalFat);
  }

  // YENİ: getDailySugar metodu eklendi
  double getDailySugar(DateTime date) {
    return _getFoodsForDate(date).fold(0.0, (sum, item) => sum + (item.totalSugar ?? 0.0));
  }

  // YENİ: getDailyFiber metodu eklendi
  double getDailyFiber(DateTime date) {
    return _getFoodsForDate(date).fold(0.0, (sum, item) => sum + (item.totalFiber ?? 0.0));
  }

  // YENİ: getDailySodium metodu eklendi
  double getDailySodium(DateTime date) {
    return _getFoodsForDate(date).fold(0.0, (sum, item) => sum + (item.totalSodium ?? 0.0));
  }


  List<ConsumedFood> getMealFoods(DateTime date, String mealType) {
    return _getFoodsForDate(date)
        .where((food) => food.mealType == mealType)
        .toList();
  }
}
