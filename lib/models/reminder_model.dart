// lib/models/reminder_model.dart - VİTAMİN EKLİ
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum ReminderType {
  sport,
  water,
  medication,
  vitamin, // YENİ EKLENDİ
  general,
}

enum RepeatInterval {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

// YENİ: Vitamin türleri
enum VitaminType {
  vitaminD,
  vitaminC,
  vitaminB12,
  vitaminB6,
  omega3,
  protein,
  creatine,
  bcaa,
  magnesium,
  zinc,
  iron,
  calcium,
  multivitamin,
  custom,
}

class Reminder {
  final String id;
  String title;
  String? description;
  ReminderType type;
  DateTime reminderDateTime;
  bool isActive;
  RepeatInterval repeatInterval;
  List<int>? customRepeatDays;
  int earlyNotificationMinutes;
  
  // YENİ: Vitamin özellikleri
  VitaminType? vitaminType;
  bool? vitaminWithFood; // Yemekle birlikte alınacak mı?

  Reminder({
    String? id,
    required this.title,
    this.description,
    required this.type,
    required this.reminderDateTime,
    this.isActive = true,
    this.repeatInterval = RepeatInterval.none,
    this.customRepeatDays,
    this.earlyNotificationMinutes = 0,
    this.vitaminType,
    this.vitaminWithFood,
  }) : id = id ?? const Uuid().v4();

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ReminderType.values.firstWhere((e) => e.toString() == json['type']),
      reminderDateTime: DateTime.parse(json['reminderDateTime']),
      isActive: json['isActive'],
      repeatInterval: RepeatInterval.values.firstWhere((e) => e.toString() == json['repeatInterval']),
      customRepeatDays: (json['customRepeatDays'] as List?)?.map((e) => e as int).toList(),
      earlyNotificationMinutes: json['earlyNotificationMinutes'] ?? 0,
      vitaminType: json['vitaminType'] != null 
          ? VitaminType.values.firstWhere((e) => e.toString() == json['vitaminType'])
          : null,
      vitaminWithFood: json['vitaminWithFood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'reminderDateTime': reminderDateTime.toIso8601String(),
      'isActive': isActive,
      'repeatInterval': repeatInterval.toString(),
      'customRepeatDays': customRepeatDays,
      'earlyNotificationMinutes': earlyNotificationMinutes,
      'vitaminType': vitaminType?.toString(),
      'vitaminWithFood': vitaminWithFood,
    };
  }

  IconData get icon {
    switch (type) {
      case ReminderType.sport:
        return Icons.sports_gymnastics;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.medication:
        return Icons.medical_services;
      case ReminderType.vitamin:
        return Icons.medication_liquid; // YENİ İKON
      case ReminderType.general:
        return Icons.task;
    }
  }
  
  // YENİ: Vitamin türü adları
  static String getVitaminTypeName(VitaminType type) {
    switch (type) {
      case VitaminType.vitaminD:
        return 'Vitamin D';
      case VitaminType.vitaminC:
        return 'Vitamin C';
      case VitaminType.vitaminB12:
        return 'Vitamin B12';
      case VitaminType.vitaminB6:
        return 'Vitamin B6';
      case VitaminType.omega3:
        return 'Omega-3';
      case VitaminType.protein:
        return 'Protein Tozu';
      case VitaminType.creatine:
        return 'Kreatin';
      case VitaminType.bcaa:
        return 'BCAA';
      case VitaminType.magnesium:
        return 'Magnezyum';
      case VitaminType.zinc:
        return 'Çinko';
      case VitaminType.iron:
        return 'Demir';
      case VitaminType.calcium:
        return 'Kalsiyum';
      case VitaminType.multivitamin:
        return 'Multivitamin';
      case VitaminType.custom:
        return 'Özel Vitamin';
    }
  }
  
  // YENİ: Vitamin önerisi metni
  static String getVitaminDescription(VitaminType type) {
    switch (type) {
      case VitaminType.vitaminD:
        return 'Kemik sağlığı ve bağışıklık sistemi için';
      case VitaminType.vitaminC:
        return 'Bağışıklık sistemi ve antioksidan';
      case VitaminType.vitaminB12:
        return 'Enerji metabolizması ve sinir sistemi';
      case VitaminType.omega3:
        return 'Kalp sağlığı ve beyin fonksiyonları';
      case VitaminType.protein:
        return 'Kas gelişimi ve onarımı için';
      case VitaminType.creatine:
        return 'Kas gücü ve performans artışı';
      case VitaminType.bcaa:
        return 'Antrenman öncesi ve sonrası kas desteği';
      case VitaminType.magnesium:
        return 'Kas fonksiyonu ve uyku kalitesi';
      default:
        return 'Genel sağlık desteği için';
    }
  }
}