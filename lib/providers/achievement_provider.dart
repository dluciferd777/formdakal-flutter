// lib/providers/achievement_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback için gerekli
import 'package:shared_preferences/shared_preferences.dart';
import '../data/achievements_data.dart';
import '../models/achievement_model.dart';

class AchievementProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<Achievement> _achievements = [];
  static const _storageKey = 'achievements_progress';

  AchievementProvider(this._prefs) {
    _loadAchievements();
    _checkAndResetAchievements();
  }

  List<Achievement> get achievements => _achievements;

  // Kilitleri açılmış başarımlar
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  // Türe göre başarımları getir
  List<Achievement> getAchievementsByType(AchievementType type) =>
      _achievements.where((a) => a.type == type).toList();

  // İlerleme olan başarımlar (günlük, haftalık, aylık)
  List<Achievement> get progressAchievements =>
      _achievements.where((a) => a.type != AchievementType.permanent).toList();

  void _loadAchievements() {
    // Tüm başarımları temel listeden yükle
    _achievements = AchievementsData.allAchievements.map((baseAchievement) {
      // Kayıtlı verilerden ilerlemeyi oku
      final savedData = _getSavedAchievementData(baseAchievement.id);

      if (savedData != null) {
        return Achievement.fromJson(
          savedData,
          id: baseAchievement.id,
          name: baseAchievement.name,
          description: baseAchievement.description,
          icon: baseAchievement.icon,
          color: baseAchievement.color,
          type: baseAchievement.type,
          targetValue: baseAchievement.targetValue,
        );
      } else {
        // İlk kez, default değerlerle başla
        return Achievement(
          id: baseAchievement.id,
          name: baseAchievement.name,
          description: baseAchievement.description,
          icon: baseAchievement.icon,
          color: baseAchievement.color,
          type: baseAchievement.type,
          targetValue: baseAchievement.targetValue,
        );
      }
    }).toList();

    notifyListeners();
  }

  Map<String, dynamic>? _getSavedAchievementData(String id) {
    final allSavedData = _prefs.getString(_storageKey);
    if (allSavedData == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(allSavedData);
      return decoded[id];
    } catch (e) {
      print("Başarım verisi okuma hatası: $e");
      return null;
    }
  }

  Future<void> _saveAchievements() async {
    final Map<String, dynamic> dataToSave = {};

    for (final achievement in _achievements) {
      dataToSave[achievement.id] = achievement.toJson();
    }

    await _prefs.setString(_storageKey, jsonEncode(dataToSave));
  }

  // Sıfırlama kontrolü ve işlemi
  void _checkAndResetAchievements() {
    bool hasChanges = false;

    for (final achievement in _achievements) {
      if (achievement.needsReset()) {
        achievement.reset();
        hasChanges = true;
        print("📅 ${achievement.name} başarımı sıfırlandı (${achievement.type})");
      }
    }

    if (hasChanges) {
      _saveAchievements();
      notifyListeners();
    }
  }

  // Manuel sıfırlama (test için)
  Future<void> resetAchievementsByType(AchievementType type) async {
    for (final achievement in _achievements) {
      if (achievement.type == type) {
        achievement.reset();
      }
    }
    await _saveAchievements();
    notifyListeners();
  }

  // Başarım ilerleme ekleme
  Future<void> addProgress(String achievementId, int value) async {
    final achievementIndex = _achievements.indexWhere((a) => a.id == achievementId);

    if (achievementIndex != -1) {
      final wasUnlocked = _achievements[achievementIndex].isUnlocked;
      _achievements[achievementIndex].addProgress(value);

      // Yeni kilidi açıldıysa bildirim göster
      if (!wasUnlocked && _achievements[achievementIndex].isUnlocked) {
        _showAchievementUnlockedNotification(_achievements[achievementIndex]);
      }

      await _saveAchievements();
      notifyListeners();
    }
  }

  // Başarım kilidi açma (eski metod - geriye uyumluluk için)
  Future<void> unlockAchievement(String id) async {
    final achievementIndex = _achievements.indexWhere((a) => a.id == id);
    if (achievementIndex != -1 && !_achievements[achievementIndex].isUnlocked) {
      await addProgress(id, 999999); // Büyük değer vererek garantili kilidi aç
    }
  }

  // Çoklu ilerleme (birden fazla başarım için)
  Future<void> addProgressMultiple(Map<String, int> progressMap) async {
    bool hasChanges = false;

    for (final entry in progressMap.entries) {
      final achievementIndex = _achievements.indexWhere((a) => a.id == entry.key);

      if (achievementIndex != -1) {
        final wasUnlocked = _achievements[achievementIndex].isUnlocked;
        _achievements[achievementIndex].addProgress(entry.value);

        if (!wasUnlocked && _achievements[achievementIndex].isUnlocked) {
          _showAchievementUnlockedNotification(_achievements[achievementIndex]);
        }

        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveAchievements();
      notifyListeners();
    }
  }

  // Başarım kilidi açıldığında bildirim
  void _showAchievementUnlockedNotification(Achievement achievement) {
    print("🎉 Başarım Açıldı: ${achievement.name}");
    // Düzeltme: Geçerli bir haptic feedback metodu kullanıldı.
    HapticFeedback.mediumImpact(); 
  }

  // İstatistikler
  int get totalAchievements => _achievements.length;
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  double get completionPercentage => totalAchievements > 0
      ? (unlockedCount / totalAchievements) * 100
      : 0.0;

  // Bugünkü ilerleme
  int get todayProgress {
    final dailyAchievements = getAchievementsByType(AchievementType.daily);
    return dailyAchievements.where((a) => a.isUnlocked).length;
  }

  // Bu haftaki ilerleme
  int get weeklyProgress {
    final weeklyAchievements = getAchievementsByType(AchievementType.weekly);
    return weeklyAchievements.where((a) => a.isUnlocked).length;
  }

  // Bu ayki ilerleme
  int get monthlyProgress {
    final monthlyAchievements = getAchievementsByType(AchievementType.monthly);
    return monthlyAchievements.where((a) => a.isUnlocked).length;
  }

  // Test fonksiyonları
  Future<void> resetAllAchievements() async {
    for (final achievement in _achievements) {
      if (achievement.type != AchievementType.permanent) {
        achievement.reset();
      }
    }
    await _saveAchievements();
    notifyListeners();
  }

  // Tüm verileri temizle
  Future<void> clearAllData() async {
    await _prefs.remove(_storageKey);
    _loadAchievements();
  }
}