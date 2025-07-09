// lib/services/notification_service.dart - HATASIZ VERSİYON
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:typed_data'; // Int64List için import

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  
  // Bildirim ID'leri
  static const int _stepReminderID = 1000;
  static const int _workoutReminderID = 1001;
  static const int _waterReminderID = 1002;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Timezone veritabanını başlat
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('🔔 Bildirime tıklandı: ${response.payload}');
        await _handleNotificationTap(response);
      },
    );

    // İzinleri iste
    await _requestPermissions();
    
    // Otomatik hatırlatmaları ayarla
    await _setupAutomaticReminders();
    
    print('✅ Bildirim servisi başlatıldı');
  }

  Future<void> _requestPermissions() async {
    // Android 13+ için bildirim izni
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    // Tam erişim izni (Android 6+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    
    if (payload != null) {
      switch (payload) {
        case 'step_reminder':
          print('🦶 Adım hatırlatması tıklandı');
          break;
        case 'workout_reminder':
          print('💪 Egzersiz hatırlatması tıklandı');
          break;
        case 'water_reminder':
          print('💧 Su içme hatırlatması tıklandı');
          break;
      }
    }
  }

  // ========== SESLİ HATIRLATICI BİLDİRİMLERİ ==========
  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // SESLİ + TİTREŞİMLİ bildirim (Hatırlatıcılar için)
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_reminders', // AYRI KANAL
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Sesli hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true, // SES AKTİF
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      autoCancel: true,
      ongoing: false,
      channelShowBadge: true,
      // TİTREŞİM PATTERN'İ
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Uzun titreşim
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ SESLİ hatırlatıcı zamanlandı: $title - $scheduledTime');
    } catch (e) {
      print('❌ Hatırlatıcı zamanlama hatası: $e');
    }
  }

  // ========== SESLİ ANINDA HATIRLATICI ==========
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_reminders',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Sesli hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true, // SES AKTİF
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('✅ SESLİ hatırlatıcı gönderildi: $title');
    } catch (e) {
      print('❌ Hatırlatıcı gönderme hatası: $e');
    }
  }

  // ========== SESLİ OLMAYAN BİLDİRİMLER ==========
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // SADECE TİTREŞİMLİ bildirim (Diğer bildirimler için)
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_general', // AYRI KANAL
      'FormdaKal Genel Bildirimler',
      channelDescription: 'Genel uygulama bildirimleri',
      importance: Importance.low, // Düşük öncelik
      priority: Priority.low,
      showWhen: true,
      enableVibration: true,
      playSound: false, // SES KAPALI
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
      ongoing: false,
      // KISA TİTREŞİM
      vibrationPattern: Int64List.fromList([0, 250, 100, 250]), // Kısa titreşim
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Sessiz bildirim zamanlandı: $title - $scheduledTime');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // Anında sessiz bildirim göster
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_general',
      'FormdaKal Genel Bildirimler',
      channelDescription: 'Genel uygulama bildirimleri',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: true,
      enableVibration: true,
      playSound: false, // SES KAPALI
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('✅ Sessiz bildirim gönderildi: $title');
    } catch (e) {
      print('❌ Bildirim gönderme hatası: $e');
    }
  }

  // ========== HATIRLATICI OTOMATIK SİSTEMLER (SESLİ) ==========
  Future<void> _setupAutomaticReminders() async {
    // SESLİ hatırlatıcılar
    await _scheduleStepReminder();
    await _scheduleWorkoutReminder();
    await _scheduleWaterReminders();
  }

  Future<void> _scheduleStepReminder() async {
    final isEnabled = _prefs.getBool('step_reminder_enabled') ?? true;
    if (!isEnabled) return;

    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 20, 0);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    // SESLİ hatırlatıcı kullan
    await scheduleReminderNotification(
      id: _stepReminderID,
      title: '🦶 Adım Hedefin Nasıl?',
      body: 'Bugün henüz hedefe ulaşmadın. Biraz yürüyüş yapmaya ne dersin?',
      scheduledTime: reminderTime,
      payload: 'step_reminder',
    );
  }

  Future<void> _scheduleWorkoutReminder() async {
    final isEnabled = _prefs.getBool('workout_reminder_enabled') ?? true;
    if (!isEnabled) return;

    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 19, 0);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    // SESLİ hatırlatıcı kullan
    await scheduleReminderNotification(
      id: _workoutReminderID,
      title: '💪 Spor Zamanı!',
      body: 'Bugün egzersiz yapmayı unutma. Formda kalmak için harekete geç!',
      scheduledTime: reminderTime,
      payload: 'workout_reminder',
    );
  }

  Future<void> _scheduleWaterReminders() async {
    final isEnabled = _prefs.getBool('water_reminder_enabled') ?? true;
    if (!isEnabled) return;

    final now = DateTime.now();
    final waterMessages = [
      '💧 Su içme zamanı! Vücudunu susuz bırakma.',
      '🥤 Hidrasyon önemli! Biraz su iç.',
      '💦 Su içmeyi unutma! Sağlığın için önemli.',
      '🚰 Su bardağını doldur ve iç!',
    ];

    for (int hour = 8; hour <= 22; hour += 2) {
      var reminderTime = DateTime(now.year, now.month, now.day, hour, 0);
      
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }

      final randomMessage = waterMessages[Random().nextInt(waterMessages.length)];
      
      // SESLİ hatırlatıcı kullan
      await scheduleReminderNotification(
        id: _waterReminderID + hour,
        title: 'Su İçme Hatırlatması',
        body: randomMessage,
        scheduledTime: reminderTime,
        payload: 'water_reminder',
      );
    }
  }

  // ========== MOTİVASYON BİLDİRİMLERİ (SESLİ DEĞİL) ==========
  Future<void> sendMotivationNotification(String type) async {
    String title, body;
    
    switch (type) {
      case 'step_milestone':
        title = '🎉 Harika! Adım Hedefine Ulaştın!';
        body = 'Bugün ${10000} adım attın! Muhteşem bir performans!';
        break;
      case 'workout_completed':
        title = '💪 Egzersiz Tamamlandı!';
        body = 'Harika bir antrenman geçirdin! Kendini ödüllendirmeyi unutma.';
        break;
      case 'weekly_progress':
        title = '📊 Haftalık Rapor Hazır!';
        body = 'Bu haftaki ilerlemen muhteşem! Raporunu kontrol et.';
        break;
      default:
        title = '🎯 Motivasyon';
        body = 'Hedeflerine ulaşmak için bir adım daha!';
    }

    // Sessiz bildirim kullan
    await showInstantNotification(
      id: Random().nextInt(1000) + 3000,
      title: title,
      body: body,
      payload: type,
    );
  }

  // Hatırlatma ayarlarını değiştir
  Future<void> toggleReminderType(String type, bool isEnabled) async {
    await _prefs.setBool('${type}_reminder_enabled', isEnabled);
    
    if (isEnabled) {
      await _setupAutomaticReminders();
      print('✅ $type hatırlatması etkinleştirildi');
    } else {
      await _cancelReminderType(type);
      print('❌ $type hatırlatması devre dışı bırakıldı');
    }
  }

  Future<void> _cancelReminderType(String type) async {
    switch (type) {
      case 'step':
        await cancelNotification(_stepReminderID);
        break;
      case 'workout':
        await cancelNotification(_workoutReminderID);
        break;
      case 'water':
        for (int hour = 8; hour <= 22; hour += 2) {
          await cancelNotification(_waterReminderID + hour);
        }
        break;
    }
  }

  // Tekil bildirim iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Bildirim iptal edildi: ID $id');
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Tüm bildirimler iptal edildi');
  }

  // Hatırlatma ayar durumunu kontrol et
  bool isReminderEnabled(String type) {
    return _prefs.getBool('${type}_reminder_enabled') ?? true;
  }

  // Test bildirimi gönder
  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🧪 Test Bildirimi',
      body: 'FormdaKal bildirimleri çalışıyor! ✅',
      payload: 'test',
    );
  }

  // SESLİ test hatırlatıcısı gönder
  Future<void> sendTestReminderNotification() async {
    await showReminderNotification(
      id: 9998,
      title: '🔔 Sesli Test Hatırlatıcısı',
      body: 'Bu hatırlatıcı sesli ve titreşimli olmalı! 🔊',
      payload: 'test_reminder',
    );
  }
}