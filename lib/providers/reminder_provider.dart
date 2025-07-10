// lib/providers/reminder_provider.dart - SESLİ BİLDİRİM EKLENDİ
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart'; // YENİ EKLENDİ

class ReminderProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService(); // YENİ EKLENDİ
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

  // YENİ EKLENDİ: Sesli bildirim ile hatırlatıcı ekleme
  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
    
    // SESLİ BİLDİRİM ZAMANLA
    if (reminder.isActive && reminder.reminderDateTime.isAfter(DateTime.now())) {
      await _scheduleNotification(reminder);
    }
    
    notifyListeners();
  }

  // YENİ EKLENDİ: Sesli bildirim ile hatırlatıcı güncelleme
  Future<void> updateReminder(Reminder updatedReminder) async {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      // Eski bildirimi iptal et
      await _notificationService.cancelNotification(_getNotificationId(updatedReminder.id));
      
      _reminders[index] = updatedReminder;
      await _saveReminders();
      
      // Yeni bildirim zamanla
      if (updatedReminder.isActive && updatedReminder.reminderDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(updatedReminder);
      }
      
      notifyListeners();
    }
  }

  // YENİ EKLENDİ: Sesli bildirim ile hatırlatıcı silme
  Future<void> deleteReminder(String reminderId) async {
    // Bildirimi iptal et
    await _notificationService.cancelNotification(_getNotificationId(reminderId));
    
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
    notifyListeners();
  }

  // YENİ EKLENDİ: Sesli bildirim ile aktif/pasif değiştirme
  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index].isActive = isActive;
      await _saveReminders();
      
      if (isActive && _reminders[index].reminderDateTime.isAfter(DateTime.now())) {
        // Aktif yapıldı - bildirim zamanla
        await _scheduleNotification(_reminders[index]);
      } else {
        // Pasif yapıldı - bildirimi iptal et
        await _notificationService.cancelNotification(_getNotificationId(reminderId));
      }
      
      notifyListeners();
    }
  }

  // YENİ EKLENDİ: Bildirim zamanlama
  Future<void> _scheduleNotification(Reminder reminder) async {
    final notificationId = _getNotificationId(reminder.id);
    
    String title = _getNotificationTitle(reminder.type);
    String body = reminder.title;
    
    try {
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: reminder.reminderDateTime,
        payload: 'reminder_${reminder.id}',
      );
      
      print('✅ Hatırlatıcı bildirim zamanlandı: ${reminder.title} - ${reminder.reminderDateTime}');
      
      // YENİ: Bildirim zamanlama kontrolü
      if (reminder.reminderDateTime.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        print('⚠️ Uyarı: Bildirim zamanı çok yakın veya geçmiş!');
        
        // Test için 5 saniye sonra bildirim gönder
        await _notificationService.scheduleNotification(
          id: notificationId + 1000,
          title: '$title (Test)',
          body: '$body - Test bildirimi (5 saniye sonra)',
          scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
          payload: 'test_reminder_${reminder.id}',
        );
        print('🧪 Test bildirimi 5 saniye sonra zamanlandı');
      }
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // YENİ EKLENDİ: Bildirim ID'si oluşturma
  int _getNotificationId(String reminderId) {
    // String ID'yi int'e çevir (hash kullanarak)
    return reminderId.hashCode.abs() % 100000; // 0-99999 arası
  }

  // YENİ EKLENDİ: Bildirim başlığı oluşturma
  String _getNotificationTitle(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return '💪 Spor Zamanı!';
      case ReminderType.water:
        return '💧 Su İçme Hatırlatması';
      case ReminderType.medication:
        return '💊 İlaç Zamanı';
      case ReminderType.general:
        return '⏰ Hatırlatıcı';
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

  // YENİ EKLENDİ: Tüm hatırlatıcıları yeniden zamanla (uygulama başlarken)
  Future<void> rescheduleAllNotifications() async {
    for (final reminder in _reminders) {
      if (reminder.isActive && reminder.reminderDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(reminder);
      }
    }
    print('🔄 Tüm hatırlatıcı bildirimleri yeniden zamanlandı');
  }

  // YENİ EKLENDİ: Test bildirimi gönder
  Future<void> sendTestNotification() async {
    await _notificationService.showInstantNotification(
      id: 99999,
      title: '🧪 Test Hatırlatıcısı',
      body: 'Hatırlatıcı bildirimleri çalışıyor! ✅',
      payload: 'test_reminder',
    );
  }

  // Tüm verileri temizleme metodu (geliştirme için faydalı olabilir)
  Future<void> clearAllReminders() async {
    // Tüm bildirimleri iptal et
    for (final reminder in _reminders) {
      await _notificationService.cancelNotification(_getNotificationId(reminder.id));
    }
    
    _reminders.clear();
    await _prefs.remove('reminders');
    notifyListeners();
  }
}