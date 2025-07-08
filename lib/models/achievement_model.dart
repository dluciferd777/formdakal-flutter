// lib/models/achievement_model.dart
import 'package:flutter/material.dart';

enum AchievementType {
  permanent, // Kalıcı başarımlar (ilk giriş, profil tamamlama vs.)
  monthly,   // Aylık sıfırlanan başarımlar
  weekly,    // Haftalık sıfırlanan başarımlar  
  daily,     // Günlük sıfırlanan başarımlar
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final int targetValue; // Hedef değer (örn: 10 antrenman)
  int currentValue; // Mevcut ilerleme
  bool isUnlocked;
  DateTime? unlockedDate;
  DateTime? lastResetDate; // Son sıfırlama tarihi

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedDate,
    this.lastResetDate,
  });

  // İlerleme yüzdesi
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  // Tamamlandı mı?
  bool get isCompleted => currentValue >= targetValue;

  // JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'lastResetDate': lastResetDate?.toIso8601String(),
    };
  }

  // JSON'dan oluşturma
  factory Achievement.fromJson(Map<String, dynamic> json, {
    required String id,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required AchievementType type,
    required int targetValue,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      color: color,
      type: type,
      targetValue: targetValue,
      currentValue: json['currentValue'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedDate: json['unlockedDate'] != null 
          ? DateTime.parse(json['unlockedDate']) 
          : null,
      lastResetDate: json['lastResetDate'] != null 
          ? DateTime.parse(json['lastResetDate']) 
          : null,
    );
  }

  // Sıfırlama gerekli mi?
  bool needsReset() {
    if (type == AchievementType.permanent) return false;
    
    final now = DateTime.now();
    
    if (lastResetDate == null) {
      return true; // İlk kez, sıfırlama tarihi belirle
    }
    
    switch (type) {
      case AchievementType.daily:
        return !_isSameDay(lastResetDate!, now);
      case AchievementType.weekly:
        return !_isSameWeek(lastResetDate!, now);
      case AchievementType.monthly:
        return !_isSameMonth(lastResetDate!, now);
      case AchievementType.permanent:
        return false;
    }
  }

  // Sıfırlama
  void reset() {
    if (type != AchievementType.permanent) {
      currentValue = 0;
      isUnlocked = false;
      unlockedDate = null;
      lastResetDate = DateTime.now();
    }
  }

  // İlerleme ekleme
  void addProgress(int value) {
    currentValue += value;
    if (currentValue >= targetValue && !isUnlocked) {
      isUnlocked = true;
      unlockedDate = DateTime.now();
    }
  }

  // Yardımcı fonksiyonlar
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final diff = date2.difference(date1).inDays;
    return diff < 7 && date1.weekday <= date2.weekday;
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }
}