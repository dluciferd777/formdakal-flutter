// lib/models/reminder_model.dart
import 'package:uuid/uuid.dart'; // uuid paketi için
import 'package:flutter/material.dart'; // IconData için

enum ReminderType {
  sport,
  water,
  medication,
  general,
}

enum RepeatInterval {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom, // Örneğin, belirli günler
}

class Reminder {
  final String id;
  String title;
  String? description;
  ReminderType type;
  DateTime reminderDateTime; // Hatırlatma tarihi ve saati
  bool isActive;
  RepeatInterval repeatInterval;
  List<int>? customRepeatDays; // Haftanın günleri (1-7, Pazartesi-Pazar)
  int earlyNotificationMinutes; // Kaç dakika erken hatırlatılacak

  Reminder({
    String? id,
    required this.title,
    this.description,
    required this.type,
    required this.reminderDateTime,
    this.isActive = true,
    this.repeatInterval = RepeatInterval.none,
    this.customRepeatDays,
    this.earlyNotificationMinutes = 0, // Varsayılan olarak erken bildirim yok
  }) : id = id ?? const Uuid().v4(); // Eğer id verilmezse yeni bir UUID oluştur

  // JSON'dan Reminder nesnesi oluşturmak için fabrika metodu
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
    );
  }

  // Reminder nesnesini JSON'a dönüştürmek için metot
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
    };
  }

  // Hatırlatma türüne göre ikon döndüren yardımcı metot
  IconData get icon {
    switch (type) {
      case ReminderType.sport:
        return Icons.sports_gymnastics;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.medication:
        return Icons.medical_services;
      case ReminderType.general:
        return Icons.task;
    }
  }
}