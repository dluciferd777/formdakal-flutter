// lib/services/notification_service.dart - SESLİ + TİTREŞİMLİ BİLDİRİM GÜÇLENDİRİLDİ
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:typed_data'; // YENİ: Int64List için

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
    
    // YENİ: Gelişmiş Android ayarları - SES + TİTREŞİM
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

    // YENİ: Bildirim kanalı oluştur (Android 8+)
    await _createNotificationChannels();

    // İzinleri iste
    await _requestPermissions();
    
    // Otomatik hatırlatmaları ayarla
    await _setupAutomaticReminders();
    
    print('✅ Bildirim servisi başlatıldı - Ses ve titreşim aktif');
  }

  // YENİ: Bildirim kanalları oluştur
  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'formdakal_reminders', // Kanal ID
      'FormdaKal Hatırlatıcılar', // Kanal adı
      description: 'Egzersiz, su içme ve diğer hatırlatıcılar', // Açıklama
      importance: Importance.high,
      enableVibration: true, // TİTREŞİM AKTİF
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Titreşim deseni
      playSound: true, // SES AKTİF
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    // Android 13+ için bildirim izni
    if (await Permission.notification.isDenied) {
      final result = await Permission.notification.request();
      print('📱 Bildirim izni: $result');
    }
    
    // Tam erişim izni (Android 6+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      print('⏰ Zamanlı bildirim izni: $result');
    }

    // YENİ: Ses ve titreşim izinleri kontrol et
    print('🔊 İzin durumları:');
    print('- Bildirim: ${await Permission.notification.status}');
    print('- Zamanlı bildirim: ${await Permission.scheduleExactAlarm.status}');
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
        default:
          if (payload.startsWith('reminder_') || payload.startsWith('test_reminder_')) {
            print('📝 Hatırlatıcı tıklandı: $payload');
          }
      }
    }
  }

  // YENİ: Güçlendirilmiş bildirim zamanlama - SES + TİTREŞİM
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // YENİ: Gelişmiş Android ayarları
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_reminders', // Yukarıda oluşturduğumuz kanal
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Egzersiz ve beslenme hatırlatıcıları',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true, // TİTREŞİM AKTİF
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Güçlü titreşim
      playSound: true, // SES AKTİF
      icon: '@mipmap/ic_launcher',
      autoCancel: true, // Tıklandığında otomatik kaybolsun
      ongoing: false, // Sürekli bildirim değil
      ticker: title, // Kısa bilgi
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      // Zamanlanan saati kontrol et
      if (scheduledTime.isBefore(DateTime.now())) {
        print('⚠️ Uyarı: Bildirim zamanı geçmiş - Şimdi gösteriliyor');
        
        // Geçmiş zamansa hemen göster
        await _notifications.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );
      } else {
        // Gelecek zamansa zamanla
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
      }

      print('✅ Bildirim zamanlandı: $title - $scheduledTime (ID: $id)');
      print('🔊 Ses ve titreşim aktif');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // YENİ: Test için anında güçlü bildirim
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_reminders',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Anında bildirimler ve test mesajları',
      importance: Importance.max, // MAKSİMUM ÖNEMLİLİK
      priority: Priority.max, // MAKSİMUM ÖNCELİK
      showWhen: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]), // Güçlü titreşim
      playSound: true,
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
      ticker: title,
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
      
      print('✅ Anında bildirim gönderildi: $title (ID: $id)');
      print('🔊 Maksimum ses ve titreşim ile');
    } catch (e) {
      print('❌ Anında bildirim hatası: $e');
    }
  }

  Future<void> _setupAutomaticReminders() async {
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
    var reminderTime = DateTime(now.year, now.month, now.day, 19, 0);
    
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

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Bildirim iptal edildi: ID $id');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Tüm bildirimler iptal edildi');
  }

  bool isReminderEnabled(String type) {
    return _prefs.getBool('${type}_reminder_enabled') ?? true;
  }

  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🧪 Test Bildirimi',
      body: 'FormdaKal bildirimleri çalışıyor! Ses ve titreşim aktif! ✅',
      payload: 'test',
    );
  }
}