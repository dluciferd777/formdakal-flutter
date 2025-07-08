// lib/providers/reminder_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

class ReminderProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<Reminder> _reminders = [];

  ReminderProvider(this._prefs) {
    _loadReminders();
  }

  List<Reminder> get reminders => _reminders;

  Future<void> _loadReminders() async {
    final remindersJson = _prefs.getString('reminders');
    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);
      _reminders = decoded.map((item) => Reminder.fromJson(item)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveReminders() async {
    final jsonList = _reminders.map((reminder) => reminder.toJson()).toList();
    await _prefs.setString('reminders', jsonEncode(jsonList));
  }

  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
    _saveReminders();
    notifyListeners();
  }

  void updateReminder(Reminder updatedReminder) {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
      _saveReminders();
      notifyListeners();
    }
  }

  void deleteReminder(String reminderId) {
    _reminders.removeWhere((r) => r.id == reminderId);
    _saveReminders();
    notifyListeners();
  }

  void toggleReminderStatus(String reminderId, bool isActive) {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index].isActive = isActive;
      _saveReminders();
      notifyListeners();
    }
  }

  // Belirli bir güne ait hatırlatmaları getiren yardımcı metod
  List<Reminder> getRemindersForDay(DateTime date) {
    return _reminders.where((reminder) {
      if (!reminder.isActive) return false;

      // Tek seferlik hatırlatmalar
      if (reminder.repeatInterval == RepeatInterval.none) {
        return reminder.reminderDateTime.year == date.year &&
               reminder.reminderDateTime.month == date.month &&
               reminder.reminderDateTime.day == date.day;
      }
      // Günlük hatırlatmalar
      else if (reminder.repeatInterval == RepeatInterval.daily) {
        return true; // Her gün geçerli
      }
      // Haftalık hatırlatmalar (belirli günlerde)
      else if (reminder.repeatInterval == RepeatInterval.weekly && reminder.customRepeatDays != null) {
        // Dart'ta Pazartesi 1, Pazar 7'dir. ISO hafta günü ile uyumlu.
        // Reminder modelinde 1-7 (Pazartesi-Pazar) olarak kabul edelim.
        // DateTime.weekday de 1-7 (Pazartesi-Pazar) döndürür.
        return reminder.customRepeatDays!.contains(date.weekday);
      }
      // Aylık hatırlatmalar (ayın belirli günü)
      else if (reminder.repeatInterval == RepeatInterval.monthly) {
        return reminder.reminderDateTime.day == date.day;
      }
      // Yıllık hatırlatmalar
      else if (reminder.repeatInterval == RepeatInterval.yearly) {
        return reminder.reminderDateTime.month == date.month &&
               reminder.reminderDateTime.day == date.day;
      }
      return false;
    }).toList();
  }

  // Tüm verileri temizleme metodu (geliştirme için faydalı olabilir)
  Future<void> clearAllReminders() async {
    _reminders.clear();
    await _prefs.remove('reminders');
    notifyListeners();
  }
}