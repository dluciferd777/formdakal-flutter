// lib/models/reminder_model.dart - ÇALIŞAN VERSİYON
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum ReminderType {
  sport,
  water,
  medication,
  vitamin, // VİTAMİN ENUM DEĞERİ
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
  }) : id = id ?? const Uuid().v4();

  // JSON'dan Reminder nesnesi oluşturmak için fabrika metodu
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReminderType.general,
      ),
      reminderDateTime: DateTime.parse(json['reminderDateTime']),
      isActive: json['isActive'] ?? true,
      repeatInterval: RepeatInterval.values.firstWhere(
        (e) => e.toString() == json['repeatInterval'],
        orElse: () => RepeatInterval.none,
      ),
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
      case ReminderType.vitamin:
        return Icons.healing; // vitamins ikonu olmadığı için healing kullan
      case ReminderType.general:
        return Icons.task;
    }
  }

  // Hatırlatma türüne göre renk döndüren yardımcı metot
  Color get color {
    switch (type) {
      case ReminderType.sport:
        return Colors.green;
      case ReminderType.water:
        return Colors.blue;
      case ReminderType.medication:
        return Colors.red;
      case ReminderType.vitamin:
        return Colors.orange;
      case ReminderType.general:
        return Colors.grey;
    }
  }

  // Hatırlatma türüne göre isim döndüren yardımcı metot
  String get typeName {
    switch (type) {
      case ReminderType.sport:
        return 'Spor';
      case ReminderType.water:
        return 'Su İçme';
      case ReminderType.medication:
        return 'İlaç';
      case ReminderType.vitamin:
        return 'Vitamin';
      case ReminderType.general:
        return 'Genel Görev';
    }
  }

  // Tekrar durumuna göre isim döndüren yardımcı metot
  String get repeatName {
    switch (repeatInterval) {
      case RepeatInterval.none:
        return 'Tek seferlik';
      case RepeatInterval.daily:
        return 'Her gün';
      case RepeatInterval.weekly:
        return 'Haftalık';
      case RepeatInterval.monthly:
        return 'Aylık';
      case RepeatInterval.yearly:
        return 'Yıllık';
      case RepeatInterval.custom:
        return 'Özel';
    }
  }

  // Hatırlatıcının bugün için geçerli olup olmadığını kontrol eder
  bool isValidForDate(DateTime date) {
    if (!isActive) return false;

    switch (repeatInterval) {
      case RepeatInterval.none:
        return reminderDateTime.year == date.year &&
               reminderDateTime.month == date.month &&
               reminderDateTime.day == date.day;
      case RepeatInterval.daily:
        return true;
      case RepeatInterval.weekly:
        if (customRepeatDays != null) {
          return customRepeatDays!.contains(date.weekday);
        }
        return reminderDateTime.weekday == date.weekday;
      case RepeatInterval.monthly:
        return reminderDateTime.day == date.day;
      case RepeatInterval.yearly:
        return reminderDateTime.month == date.month &&
               reminderDateTime.day == date.day;
      case RepeatInterval.custom:
        if (customRepeatDays != null) {
          return customRepeatDays!.contains(date.weekday);
        }
        return false;
    }
  }

  // Hatırlatıcının geçmiş olup olmadığını kontrol eder
  bool get isPast {
    return reminderDateTime.isBefore(DateTime.now());
  }

  // Hatırlatıcının bugün için olup olmadığını kontrol eder
  bool get isToday {
    final now = DateTime.now();
    return reminderDateTime.year == now.year &&
           reminderDateTime.month == now.month &&
           reminderDateTime.day == now.day;
  }

  // Hatırlatıcının yaklaşan (sonraki 24 saat) olup olmadığını kontrol eder
  bool get isUpcoming {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    return reminderDateTime.isAfter(now) && reminderDateTime.isBefore(tomorrow);
  }

  // Kopyalama metodu (güncellemeler için kullanışlı)
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    ReminderType? type,
    DateTime? reminderDateTime,
    bool? isActive,
    RepeatInterval? repeatInterval,
    List<int>? customRepeatDays,
    int? earlyNotificationMinutes,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      isActive: isActive ?? this.isActive,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      earlyNotificationMinutes: earlyNotificationMinutes ?? this.earlyNotificationMinutes,
    );
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, type: $type, dateTime: $reminderDateTime, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}