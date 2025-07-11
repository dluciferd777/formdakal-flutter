// lib/providers/user_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:formdakal/models/weight_history_model.dart';
import 'package:formdakal/services/calorie_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'achievement_provider.dart';

class UserProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  // HATA DÜZELTME: Provider'lar artık birbirlerine BuildContext üzerinden değil,
  // doğrudan bağımlılık olarak bağlanıyor. Bu, daha güvenli ve doğru bir yöntemdir.
  late AchievementProvider _achievementProvider;

  UserModel? _user;
  List<WeightHistoryModel> _weightHistory = [];

  static const _userKey = 'user_profile';
  static const _weightHistoryKey = 'user_weight_history';

  // HATA DÜZELTME: Constructor artık BuildContext almıyor.
  UserProvider(this._prefs, this._achievementProvider) {
    loadUser();
  }

  // DÜZELTME: main.dart'taki ChangeNotifierProxyProvider'ın çalışabilmesi için
  // bağımlılıkları güncelleyen bir metod eklendi.
  void updateDependencies(AchievementProvider achievementProvider) {
    _achievementProvider = achievementProvider;
  }

  UserModel? get user => _user;
  List<WeightHistoryModel> get weightHistory => _weightHistory;

  Future<void> loadUser() async {
    final String? jsonString = _prefs.getString(_userKey);
    if (jsonString != null) {
      _user = UserModel.fromJson(jsonDecode(jsonString));
    }
    await _loadWeightHistory();
    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    bool isFirstSave = _user == null;

    // Kilo değiştiyse veya ilk kayıt ise kilo geçmişine ekle.
    if (_user == null || (_user != null && _user!.weight != user.weight)) {
      final newWeightEntry =
          WeightHistoryModel(weight: user.weight, date: DateTime.now());
      _weightHistory.add(newWeightEntry);
      await _saveWeightHistory();
    }
    _user = user;
    final String jsonString = jsonEncode(_user!.toJson());
    await _prefs.setString(_userKey, jsonString);

    _checkProfileAchievements(isFirstSave);
    notifyListeners();
  }

  void _checkProfileAchievements(bool isFirstSave) {
    if (_user == null) return;
    
    // HATA DÜZELTME: Artık Provider.of(context) kullanılmıyor.
    // Bağımlılık olarak enjekte edilen _achievementProvider kullanılıyor.
    if (isFirstSave) {
      _achievementProvider.unlockAchievement('profile_complete');
      _achievementProvider.unlockAchievement('first_login'); // İlk giriş başarımı eklendi
    }
  }

  Future<void> updateUser(UserModel updatedUser) async =>
      await saveUser(updatedUser);

  Future<void> updateProfileImage(String? imagePath) async {
    if (_user != null) {
      _user!.profileImagePath = imagePath;
      await saveUser(_user!);
    }
  }

  Future<void> deleteProfileImage() async {
    if (_user != null) {
      _user!.profileImagePath = null;
      await saveUser(_user!);
    }
  }

  double getDailyWaterIntake(DateTime date) {
    if (_user == null) return 0.0;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _user!.dailyWaterIntake[dateKey] ?? 0.0;
  }

  Future<void> addWater(double amountLiters) async {
    if (_user == null) return;
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentIntake = getDailyWaterIntake(DateTime.now());
    _user!.dailyWaterIntake[dateKey] = currentIntake + amountLiters;
    await saveUser(_user!);
  }

  String getBMICategory() {
    if (_user == null) return 'Bilinmiyor';
    return CalorieService.getBMICategory(_user!.bmi);
  }

  Future<void> _loadWeightHistory() async {
    final dataString = _prefs.getString(_weightHistoryKey);
    if (dataString != null) {
      _weightHistory = (jsonDecode(dataString) as List)
          .map((item) => WeightHistoryModel.fromJson(item))
          .toList();
    }
  }

  Future<void> _saveWeightHistory() async {
    await _prefs.setString(_weightHistoryKey,
        jsonEncode(_weightHistory.map((item) => item.toJson()).toList()));
  }
}
