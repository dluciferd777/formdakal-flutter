// lib/services/notification_service.dart - SON ÇALIŞAN VERSİYON
import 'dart:typed_data';
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
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Timezone veritabanını başlat
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      
      // Android ayarları
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
      
      _isInitialized = true;
      print('✅ Bildirim servisi başlatıldı');
      
    } catch (e) {
      print('❌ Bildirim servisi başlatma hatası: $e');
      rethrow;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final notificationStatus = await Permission.notification.request();
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      
      print('📱 Bildirim izni: ${notificationStatus.isGranted}');
      print('⏰ Kesin alarm izni: ${exactAlarmStatus.isGranted}');
      
      return notificationStatus.isGranted;
    } catch (e) {
      print('❌ İzin isteme hatası: $e');
      return false;
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    
    if (payload != null) {
      print('🔔 Bildirim payload: $payload');
      
      if (payload.startsWith('reminder_')) {
        print('📋 Hatırlatıcı bildirimi açıldı');
      } else {
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
  }

  // Ana bildirim zamanlama fonksiyonu
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    // Geçmiş zaman kontrolü
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ Geçmiş zamana bildirim planlanamaz: $scheduledTime');
      return;
    }

    // Android ayarları - HER PARAMETRE AYRI SATIRDA
    final androidDetails = AndroidNotificationDetails(
      'formdakal_reminders',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Egzersiz, beslenme ve hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: playSound,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration ? Int64List.fromList([0, 1000, 500, 1000]) : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      autoCancel: true,
      ongoing: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Bildirim zamanlandı: $title - $scheduledTime');
      
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
      rethrow;
    }
  }

  // Anında bildirim göster
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final androidDetails = AndroidNotificationDetails(
      'formdakal_instant',
      'FormdaKal Anında Bildirimler',
      channelDescription: 'Anında bildirimler ve motivasyon mesajları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: playSound,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration ? Int64List.fromList([0, 500, 200, 500]) : null,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      autoCancel: true,
    );

    final notificationDetails = NotificationDetails(
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
      rethrow;
    }
  }

  // Motivasyon bildirimi gönder
  Future<void> sendMotivationNotification(String type) async {
    String title, body;
    
    switch (type) {
      case 'step_milestone':
        title = '🎉 Harika! Adım Hedefine Ulaştın!';
        body = 'Bugün 10000 adım attın! Muhteşem bir performans!';
        break;
      case 'workout_completed':
        title = '💪 Egzersiz Tamamlandı!';
        body = 'Harika bir antrenman geçirdin! Kendini ödüllendirmeyi unutma.';
        break;
      case 'weekly_progress':
        title = '📊 Haftalık Rapor Hazır!';
        body = 'Bu haftaki ilerlemen muhteşem! Raporunu kontrol et.';
        break;
      case 'vitamin_reminder':
        title = '🍊 Vitamin Zamanı!';
        body = 'Günlük vitamin alımını unutma! Sağlığın için önemli.';
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
      playSound: true,
      enableVibration: true,
    );
  }

  // Tekil bildirim iptal et
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('🗑️ Bildirim iptal edildi: ID $id');
    } catch (e) {
      print('❌ Bildirim iptal etme hatası: $e');
    }
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('🗑️ Tüm bildirimler iptal edildi');
    } catch (e) {
      print('❌ Tüm bildirimleri iptal etme hatası: $e');
    }
  }

  // Hatırlatma ayar durumunu kontrol et
  bool isReminderEnabled(String type) {
    return _prefs.getBool('${type}_reminder_enabled') ?? true;
  }

  // Hatırlatma ayarlarını değiştir
  Future<void> toggleReminderType(String type, bool isEnabled) async {
    await _prefs.setBool('${type}_reminder_enabled', isEnabled);
    print('${isEnabled ? '✅' : '❌'} $type hatırlatması ${isEnabled ? 'etkinleştirildi' : 'devre dışı bırakıldı'}');
  }

  // Test bildirimi gönder
  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🧪 Test Bildirimi',
      body: 'FormdaKal bildirimleri çalışıyor! Ses ve titreşim aktif ✅',
      payload: 'test',
      playSound: true,
      enableVibration: true,
    );
  }

  // Bildirim izinlerini kontrol et
  Future<bool> checkPermissions() async {
    try {
      final notificationStatus = await Permission.notification.status;
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      
      print('📱 Bildirim izni: ${notificationStatus.isGranted}');
      print('⏰ Kesin alarm izni: ${exactAlarmStatus.isGranted}');
      
      return notificationStatus.isGranted;
    } catch (e) {
      print('❌ İzin kontrolü hatası: $e');
      return false;
    }
  }

  // Bildirim geçmişini temizle
  Future<void> clearNotificationHistory() async {
    try {
      await cancelAllNotifications();
      print('🧹 Bildirim geçmişi temizlendi');
    } catch (e) {
      print('❌ Bildirim geçmişi temizleme hatası: $e');
    }
  }
}