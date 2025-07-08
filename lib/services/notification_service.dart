// lib/services/notification_service.dart - GELİŞTİRİLMİŞ VERSİYON
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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
  static const int _customReminderBaseID = 2000;

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

  // Klasik hatırlatma zamanlama (mevcut kod ile uyumlu)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_channel',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Egzersiz ve beslenme hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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

      print('✅ Bildirim zamanlandı: $title - $scheduledTime');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // Otomatik hatırlatmaları ayarla
  Future<void> _setupAutomaticReminders() async {
    // Günlük adım hatırlatması - akşam 8'de
    await _scheduleStepReminder();
    
    // Egzersiz hatırlatması - akşam 7'de
    await _scheduleWorkoutReminder();
    
    // Su içme hatırlatması - her 2 saatte bir
    await _scheduleWaterReminders();
  }

  Future<void> _scheduleStepReminder() async {
    final isEnabled = _prefs.getBool('step_reminder_enabled') ?? true;
    if (!isEnabled) return;

    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 20, 0); // 20:00
    
    // Eğer saat geçmişse yarın için ayarla
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
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
    var reminderTime = DateTime(now.year, now.month, now.day, 19, 0); // 19:00
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await scheduleNotification(
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

    // 08:00 - 22:00 arası her 2 saatte bir hatırlatma
    for (int hour = 8; hour <= 22; hour += 2) {
      var reminderTime = DateTime(now.year, now.month, now.day, hour, 0);
      
      if (reminderTime.isBefore(now)) {
        reminderTime = reminderTime.add(const Duration(days: 1));
      }

      final randomMessage = waterMessages[Random().nextInt(waterMessages.length)];
      
      await scheduleNotification(
        id: _waterReminderID + hour,
        title: 'Su İçme Hatırlatması',
        body: randomMessage,
        scheduledTime: reminderTime,
        payload: 'water_reminder',
      );
    }
  }

  // Motivasyon bildirimi gönder
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

    await showInstantNotification(
      id: Random().nextInt(1000) + 3000,
      title: title,
      body: body,
      payload: type,
    );
  }

  // Anında bildirim göster
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_instant',
      'FormdaKal Anında Bildirimler',
      channelDescription: 'Anında bildirimler ve motivasyon mesajları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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
      
      print('✅ Anında bildirim gönderildi: $title');
    } catch (e) {
      print('❌ Anında bildirim hatası: $e');
    }
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
        // Su hatırlatmalarını iptal et (8 farklı saat)
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
}