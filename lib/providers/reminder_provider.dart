// lib/providers/reminder_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<Reminder> _reminders = [];
  final NotificationService _notificationService = NotificationService();

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

  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
    
    // Bildirim zamanlama
    if (reminder.isActive) {
      await _scheduleReminderNotifications(reminder);
    }
    
    // Başarı bildirimi göster
    await _notificationService.showInstantNotification(
      id: 10000 + _reminders.length,
      title: '✅ Hatırlatıcı Oluşturuldu',
      body: '${reminder.title} başarıyla eklendi!',
      payload: 'reminder_created',
    );
    
    notifyListeners();
  }

  Future<void> updateReminder(Reminder updatedReminder) async {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      // Eski bildirimleri iptal et
      await _cancelReminderNotifications(_reminders[index]);
      
      _reminders[index] = updatedReminder;
      await _saveReminders();
      
      // Yeni bildirimleri zamanla
      if (updatedReminder.isActive) {
        await _scheduleReminderNotifications(updatedReminder);
      }
      
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminderToDelete = _reminders.firstWhere((r) => r.id == reminderId);
    
    // Bildirimleri iptal et
    await _cancelReminderNotifications(reminderToDelete);
    
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
    
    // Silme bildirimi göster
    await _notificationService.showInstantNotification(
      id: 10100,
      title: '🗑️ Hatırlatıcı Silindi',
      body: '${reminderToDelete.title} başarıyla silindi.',
      payload: 'reminder_deleted',
    );
    
    notifyListeners();
  }

  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final reminder = _reminders[index];
      
      if (!isActive) {
        // Devre dışı bırakılıyorsa bildirimleri iptal et
        await _cancelReminderNotifications(reminder);
      }
      
      _reminders[index].isActive = isActive;
      await _saveReminders();
      
      if (isActive) {
        // Etkinleştiriliyorsa bildirimleri yeniden zamanla
        await _scheduleReminderNotifications(_reminders[index]);
        
        await _notificationService.showInstantNotification(
          id: 10200,
          title: '🔔 Hatırlatıcı Etkinleştirildi',
          body: '${reminder.title} hatırlatıcısı aktif!',
          payload: 'reminder_enabled',
        );
      } else {
        await _notificationService.showInstantNotification(
          id: 10201,
          title: '🔕 Hatırlatıcı Devre Dışı',
          body: '${reminder.title} hatırlatıcısı kapatıldı.',
          payload: 'reminder_disabled',
        );
      }
      
      notifyListeners();
    }
  }

  // Hatırlatma için bildirimleri zamanla
  Future<void> _scheduleReminderNotifications(Reminder reminder) async {
    if (!reminder.isActive) return;

    final baseId = reminder.id.hashCode;
    final now = DateTime.now();

    try {
      switch (reminder.repeatInterval) {
        case RepeatInterval.none:
          // Tek seferlik hatırlatma
          if (reminder.reminderDateTime.isAfter(now)) {
            await _notificationService.scheduleNotification(
              id: baseId,
              title: reminder.title,
              body: reminder.description ?? 'Hatırlatıcı zamanı!',
              scheduledTime: reminder.reminderDateTime,
              payload: 'reminder_${reminder.id}',
            );
          }
          break;

        case RepeatInterval.daily:
          // Günlük hatırlatma - sonraki 30 günü zamanla
          for (int i = 0; i < 30; i++) {
            final scheduleDate = DateTime(
              now.year,
              now.month,
              now.day + i,
              reminder.reminderDateTime.hour,
              reminder.reminderDateTime.minute,
            );
            
            if (scheduleDate.isAfter(now)) {
              await _notificationService.scheduleNotification(
                id: baseId + i,
                title: reminder.title,
                body: reminder.description ?? 'Günlük hatırlatıcın!',
                scheduledTime: scheduleDate,
                payload: 'reminder_${reminder.id}',
              );
            }
          }
          break;

        case RepeatInterval.weekly:
          // Haftalık hatırlatma
          if (reminder.customRepeatDays != null) {
            for (int week = 0; week < 4; week++) {
              for (int dayOfWeek in reminder.customRepeatDays!) {
                final scheduleDate = _getNextWeekday(now, dayOfWeek, week);
                final scheduledDateTime = DateTime(
                  scheduleDate.year,
                  scheduleDate.month,
                  scheduleDate.day,
                  reminder.reminderDateTime.hour,
                  reminder.reminderDateTime.minute,
                );
                
                if (scheduledDateTime.isAfter(now)) {
                  await _notificationService.scheduleNotification(
                    id: baseId + (week * 10) + dayOfWeek,
                    title: reminder.title,
                    body: reminder.description ?? 'Haftalık hatırlatıcın!',
                    scheduledTime: scheduledDateTime,
                    payload: 'reminder_${reminder.id}',
                  );
                }
              }
            }
          }
          break;

        case RepeatInterval.monthly:
          // Aylık hatırlatma - sonraki 12 ayı zamanla
          for (int i = 0; i < 12; i++) {
            final scheduleDate = DateTime(
              now.year,
              now.month + i,
              reminder.reminderDateTime.day,
              reminder.reminderDateTime.hour,
              reminder.reminderDateTime.minute,
            );
            
            if (scheduleDate.isAfter(now)) {
              await _notificationService.scheduleNotification(
                id: baseId + (i * 100),
                title: reminder.title,
                body: reminder.description ?? 'Aylık hatırlatıcın!',
                scheduledTime: scheduleDate,
                payload: 'reminder_${reminder.id}',
              );
            }
          }
          break;

        case RepeatInterval.yearly:
          // Yıllık hatırlatma - sonraki 5 yılı zamanla
          for (int i = 0; i < 5; i++) {
            final scheduleDate = DateTime(
              now.year + i,
              reminder.reminderDateTime.month,
              reminder.reminderDateTime.day,
              reminder.reminderDateTime.hour,
              reminder.reminderDateTime.minute,
            );
            
            if (scheduleDate.isAfter(now)) {
              await _notificationService.scheduleNotification(
                id: baseId + (i * 1000),
                title: reminder.title,
                body: reminder.description ?? 'Yıllık hatırlatıcın!',
                scheduledTime: scheduleDate,
                payload: 'reminder_${reminder.id}',
              );
            }
          }
          break;

        case RepeatInterval.custom:
          // Özel tekrar aralığı - haftalık gibi davran
          if (reminder.customRepeatDays != null) {
            for (int week = 0; week < 4; week++) {
              for (int dayOfWeek in reminder.customRepeatDays!) {
                final scheduleDate = _getNextWeekday(now, dayOfWeek, week);
                final scheduledDateTime = DateTime(
                  scheduleDate.year,
                  scheduleDate.month,
                  scheduleDate.day,
                  reminder.reminderDateTime.hour,
                  reminder.reminderDateTime.minute,
                );
                
                if (scheduledDateTime.isAfter(now)) {
                  await _notificationService.scheduleNotification(
                    id: baseId + (week * 10) + dayOfWeek + 5000,
                    title: reminder.title,
                    body: reminder.description ?? 'Özel hatırlatıcın!',
                    scheduledTime: scheduledDateTime,
                    payload: 'reminder_${reminder.id}',
                  );
                }
              }
            }
          }
          break;
      }

      print('✅ ${reminder.title} için bildirimler zamanlandı');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // Hatırlatma bildirimlerini iptal et
  Future<void> _cancelReminderNotifications(Reminder reminder) async {
    final baseId = reminder.id.hashCode;
    
    try {
      // Farklı repeat interval'lara göre ID'leri iptal et
      switch (reminder.repeatInterval) {
        case RepeatInterval.none:
          await _notificationService.cancelNotification(baseId);
          break;
        case RepeatInterval.daily:
          for (int i = 0; i < 30; i++) {
            await _notificationService.cancelNotification(baseId + i);
          }
          break;
        case RepeatInterval.weekly:
          for (int week = 0; week < 4; week++) {
            for (int day = 1; day <= 7; day++) {
              await _notificationService.cancelNotification(baseId + (week * 10) + day);
            }
          }
          break;
        case RepeatInterval.monthly:
          for (int i = 0; i < 12; i++) {
            await _notificationService.cancelNotification(baseId + (i * 100));
          }
          break;
        case RepeatInterval.yearly:
          for (int i = 0; i < 5; i++) {
            await _notificationService.cancelNotification(baseId + (i * 1000));
          }
          break;
        case RepeatInterval.custom:
          for (int week = 0; week < 4; week++) {
            for (int day = 1; day <= 7; day++) {
              await _notificationService.cancelNotification(baseId + (week * 10) + day + 5000);
            }
          }
          break;
      }

      print('🗑️ ${reminder.title} bildirimleri iptal edildi');
    } catch (e) {
      print('❌ Bildirim iptal hatası: $e');
    }
  }

  // Haftanın belirli gününü hesapla
  DateTime _getNextWeekday(DateTime from, int weekday, int weekOffset) {
    final daysUntilWeekday = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: daysUntilWeekday + (weekOffset * 7)));
  }

  // Test bildirimi gönder
  Future<void> sendTestNotification() async {
    await _notificationService.sendTestNotification();
  }

  // Belirli bir güne ait hatırlatmaları getiren yardımcı metod
  List<Reminder> getRemindersForDay(DateTime date) {
    return _reminders.where((reminder) {
      if (!reminder.isActive) return false;

      switch (reminder.repeatInterval) {
        case RepeatInterval.none:
          return reminder.reminderDateTime.year == date.year &&
                 reminder.reminderDateTime.month == date.month &&
                 reminder.reminderDateTime.day == date.day;
        case RepeatInterval.daily:
          return true;
        case RepeatInterval.weekly:
          if (reminder.customRepeatDays != null) {
            return reminder.customRepeatDays!.contains(date.weekday);
          }
          return false;
        case RepeatInterval.monthly:
          return reminder.reminderDateTime.day == date.day;
        case RepeatInterval.yearly:
          return reminder.reminderDateTime.month == date.month &&
                 reminder.reminderDateTime.day == date.day;
        case RepeatInterval.custom:
          // Custom interval - haftalık gibi davran
          if (reminder.customRepeatDays != null) {
            return reminder.customRepeatDays!.contains(date.weekday);
          }
          return false;
      }
    }).toList();
  }

  // Tüm verileri temizleme metodu
  Future<void> clearAllReminders() async {
    // Tüm bildirimleri iptal et
    for (final reminder in _reminders) {
      await _cancelReminderNotifications(reminder);
    }
    
    _reminders.clear();
    await _prefs.remove('reminders');
    notifyListeners();
  }

  // Yaklaşan hatırlatmaları getir (bugünden itibaren 7 gün)
  List<Reminder> getUpcomingReminders() {
    final now = DateTime.now();
    
    List<Reminder> upcoming = [];
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayReminders = getRemindersForDay(checkDate);
      upcoming.addAll(dayReminders);
    }
    
    return upcoming;
  }
}