// lib/providers/reminder_provider.dart - ÇALIŞAN VERSİYON
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<Reminder> _reminders = [];

  ReminderProvider(this._prefs) {
    _loadReminders();
  }

  List<Reminder> get reminders => _reminders;

  Future<void> _loadReminders() async {
    try {
      final remindersJson = _prefs.getString('reminders');
      if (remindersJson != null) {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        _reminders = decoded.map((item) => Reminder.fromJson(item)).toList();
        
        // Uygulama başlatıldığında aktif hatırlatmaları yeniden planla
        await _rescheduleActiveReminders();
      }
      notifyListeners();
    } catch (e) {
      print('Hatırlatıcı yükleme hatası: $e');
    }
  }

  Future<void> _saveReminders() async {
    try {
      final jsonList = _reminders.map((reminder) => reminder.toJson()).toList();
      await _prefs.setString('reminders', jsonEncode(jsonList));
    } catch (e) {
      print('Hatırlatıcı kaydetme hatası: $e');
    }
  }

  Future<void> _rescheduleActiveReminders() async {
    try {
      // Önce tüm eski bildirimleri iptal et
      for (final reminder in _reminders) {
        await NotificationService().cancelNotification(reminder.id.hashCode);
      }

      // Aktif ve gelecekteki hatırlatmaları yeniden planla
      for (final reminder in _reminders) {
        if (reminder.isActive && reminder.reminderDateTime.isAfter(DateTime.now())) {
          await _scheduleNotification(reminder);
        }
      }
    } catch (e) {
      print('Hatırlatma yeniden planlama hatası: $e');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      _reminders.add(reminder);
      await _saveReminders();
      
      // Bildirim planla
      if (reminder.isActive && reminder.reminderDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(reminder);
      }
      
      notifyListeners();
    } catch (e) {
      print('Hatırlatıcı ekleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder updatedReminder) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
      if (index != -1) {
        // Eski bildirimi iptal et
        await NotificationService().cancelNotification(updatedReminder.id.hashCode);
        
        _reminders[index] = updatedReminder;
        await _saveReminders();
        
        // Yeni bildirim planla
        if (updatedReminder.isActive && updatedReminder.reminderDateTime.isAfter(DateTime.now())) {
          await _scheduleNotification(updatedReminder);
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Hatırlatıcı güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      
      // Bildirimi iptal et
      await NotificationService().cancelNotification(reminder.id.hashCode);
      
      _reminders.removeWhere((r) => r.id == reminderId);
      await _saveReminders();
      notifyListeners();
    } catch (e) {
      print('Hatırlatıcı silme hatası: $e');
      rethrow;
    }
  }

  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        _reminders[index].isActive = isActive;
        await _saveReminders();
        
        if (isActive && _reminders[index].reminderDateTime.isAfter(DateTime.now())) {
          // Aktif yapıldığında bildirim planla
          await _scheduleNotification(_reminders[index]);
        } else {
          // Pasif yapıldığında bildirimi iptal et
          await NotificationService().cancelNotification(_reminders[index].id.hashCode);
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Hatırlatıcı durumu değiştirme hatası: $e');
      rethrow;
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    try {
      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: _getNotificationTitle(reminder.type),
        body: reminder.title,
        scheduledTime: reminder.reminderDateTime,
        payload: 'reminder_${reminder.id}',
      );
      print('✅ Bildirim planlandı: ${reminder.title} - ${reminder.reminderDateTime}');
    } catch (e) {
      print('❌ Bildirim planlama hatası: $e');
    }
  }

  String _getNotificationTitle(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return '🏃‍♂️ Spor Zamanı!';
      case ReminderType.water:
        return '💧 Su İçme Hatırlatması';
      case ReminderType.medication:
        return '💊 İlaç Zamanı';
      case ReminderType.vitamin:
        return '🍊 Vitamin Zamanı';
      case ReminderType.general:
        return '📋 Hatırlatma';
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

  // Bugünkü hatırlatmaları getir
  List<Reminder> getTodaysReminders() {
    return getRemindersForDay(DateTime.now());
  }

  // Aktif hatırlatıcı sayısı
  int get activeReminderCount => _reminders.where((r) => r.isActive).length;

  // Pasif hatırlatıcı sayısı
  int get inactiveReminderCount => _reminders.where((r) => !r.isActive).length;

  // Yaklaşan hatırlatmaları getir (sonraki 24 saat)
  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return _reminders.where((reminder) {
      if (!reminder.isActive) return false;
      return reminder.reminderDateTime.isAfter(now) && 
             reminder.reminderDateTime.isBefore(tomorrow);
    }).toList()..sort((a, b) => a.reminderDateTime.compareTo(b.reminderDateTime));
  }

  // Geçmiş hatırlatmaları getir
  List<Reminder> getPastReminders() {
    final now = DateTime.now();
    
    return _reminders.where((reminder) {
      return reminder.reminderDateTime.isBefore(now);
    }).toList()..sort((a, b) => b.reminderDateTime.compareTo(a.reminderDateTime));
  }

  // Test bildirimi gönder
  Future<void> sendTestNotification() async {
    try {
      await NotificationService().sendTestNotification();
    } catch (e) {
      print('Test bildirimi gönderme hatası: $e');
      rethrow;
    }
  }

  // Tüm bildirimleri yeniden planla (ayarlar değiştiğinde kullanılabilir)
  Future<void> rescheduleAllNotifications() async {
    await _rescheduleActiveReminders();
  }

  // Tüm verileri temizleme metodu (geliştirme için faydalı olabilir)
  Future<void> clearAllReminders() async {
    try {
      // Tüm bildirimleri iptal et
      for (final reminder in _reminders) {
        await NotificationService().cancelNotification(reminder.id.hashCode);
      }
      
      _reminders.clear();
      await _prefs.remove('reminders');
      notifyListeners();
    } catch (e) {
      print('Tüm hatırlatıcıları temizleme hatası: $e');
      rethrow;
    }
  }

  // Bildirim ayarlarını kontrol et
  Future<bool> checkNotificationPermissions() async {
    return true; // Varsayılan olarak true döndür
  }
}