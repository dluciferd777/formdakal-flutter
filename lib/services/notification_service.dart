// lib/services/notification_service.dart - TAM ÇALIŞAN VERSİYON
import 'package:flutter/material.dart'; // Color için gerekli import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Bildirim ID'leri
  static const int _stepReminderID = 1000;
  static const int _workoutReminderID = 1001;
  static const int _waterReminderID = 1002;

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

      // iOS ayarları (gelecekte kullanım için)
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          print('🔔 Bildirime tıklandı: ${response.payload}');
          await _handleNotificationTap(response);
        },
      );

      // Bildirim kanallarını oluştur (Android 8+)
      await _createNotificationChannels();
      
      // İzinleri iste
      await _requestPermissions();
      
      // Otomatik hatırlatmaları ayarla
      await _setupAutomaticReminders();
      
      _isInitialized = true;
      print('✅ Bildirim servisi tamamen başlatıldı');
      
      // Test bildirimi gönder (başlangıçta)
      await _sendWelcomeNotification();
      
    } catch (e) {
      print('❌ Bildirim servisi başlatma hatası: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Ana hatırlatıcı kanalı
      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'formdakal_reminders',
        'FormdaKal Hatırlatıcılar',
        description: 'Egzersiz, beslenme ve su içme hatırlatıcıları',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      // Motivasyon bildirimleri kanalı
      const AndroidNotificationChannel motivationChannel = AndroidNotificationChannel(
        'formdakal_motivation',
        'FormdaKal Motivasyon',
        description: 'Başarı ve motivasyon bildirimleri',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      // Anında bildirim kanalı
      const AndroidNotificationChannel instantChannel = AndroidNotificationChannel(
        'formdakal_instant',
        'FormdaKal Anında Bildirimler',
        description: 'Anında bildirimler ve sistem mesajları',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await plugin?.createNotificationChannel(reminderChannel);
      await plugin?.createNotificationChannel(motivationChannel);
      await plugin?.createNotificationChannel(instantChannel);
      
      print('✅ Android bildirim kanalları oluşturuldu');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ için bildirim izni
        final notificationStatus = await Permission.notification.status;
        if (notificationStatus.isDenied) {
          final result = await Permission.notification.request();
          print('📱 Bildirim izni durumu: $result');
        }
        
        // Tam zamanlı bildirimler için izin (Android 6+)
        final alarmStatus = await Permission.scheduleExactAlarm.status;
        if (alarmStatus.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          print('⏰ Zamanlanmış bildirim izni durumu: $result');
        }

        // Pil optimizasyonu uyarısı göster
        await _showBatteryOptimizationWarning();
      }
    } catch (e) {
      print('❌ İzin isteme hatası: $e');
    }
  }

  Future<void> _showBatteryOptimizationWarning() async {
    // Kullanıcıya pil optimizasyonunu kapatması için bildirim gönder
    await showInstantNotification(
      id: 99999,
      title: '🔋 Önemli: Pil Optimizasyonu',
      body: 'Bildirimlerin düzenli gelmesi için pil optimizasyonunu kapatın.',
      payload: 'battery_optimization',
    );
  }

  Future<void> _sendWelcomeNotification() async {
    // Uygulama ilk açıldığında hoş geldin bildirimi
    final isFirstLaunch = _prefs.getBool('first_launch') ?? true;
    if (isFirstLaunch) {
      await showInstantNotification(
        id: 1,
        title: '🎉 FormdaKal\'a Hoş Geldin!',
        body: 'Bildirimler aktif! Artık hedeflerini takip edebilirsin.',
        payload: 'welcome',
      );
      await _prefs.setBool('first_launch', false);
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
        case 'battery_optimization':
          print('🔋 Pil optimizasyonu bildirimi tıklandı');
          break;
        case 'welcome':
          print('🎉 Hoş geldin bildirimi tıklandı');
          break;
        default:
          if (payload.startsWith('reminder_')) {
            print('📅 Özel hatırlatma tıklandı: $payload');
          }
      }
    }
  }

  // Klasik hatırlatma zamanlama (ReminderProvider ile uyumlu)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Geçmiş tarihler için kontrol
      if (scheduledTime.isBefore(DateTime.now())) {
        print('⚠️ Geçmiş tarih için bildirim zamanlanamaz: $scheduledTime');
        return;
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'formdakal_reminders',
        'FormdaKal Hatırlatıcılar',
        channelDescription: 'Egzersiz ve beslenme hatırlatıcıları',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF4CAF50), // Yeşil renk
        autoCancel: true,
        ongoing: false,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'FormdaKal',
        ),
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('✅ Bildirim zamanlandı: $title - ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
      
      // Hata durumunda fallback olarak anında bildirim gönder
      try {
        await showInstantNotification(
          id: id,
          title: '⚠️ $title',
          body: 'Zamanlama hatası: $body',
          payload: payload,
        );
      } catch (e2) {
        print('❌ Fallback bildirimi de başarısız: $e2');
      }
    }
  }

  // Otomatik hatırlatmaları ayarla
  Future<void> _setupAutomaticReminders() async {
    try {
      // Günlük adım hatırlatması - akşam 8'de
      await _scheduleStepReminder();
      
      // Egzersiz hatırlatması - akşam 7'de
      await _scheduleWorkoutReminder();
      
      // Su içme hatırlatması - her 2 saatte bir
      await _scheduleWaterReminders();
      
      print('✅ Otomatik hatırlatmalar ayarlandı');
    } catch (e) {
      print('❌ Otomatik hatırlatma ayarlama hatası: $e');
    }
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
      '💙 Vücudun su istiyor! İhtiyacını karşıla.',
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
        body = 'Bugün 10.000 adım attın! Muhteşem bir performans!';
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
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_instant',
      'FormdaKal Anında Bildirimler',
      channelDescription: 'Anında bildirimler ve motivasyon mesajları',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF4CAF50), // Yeşil renk
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'FormdaKal',
      ),
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
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

  // Bildirim durumunu kontrol et
  Future<bool> areNotificationsEnabled() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin != null) {
      return await plugin.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  // Bekleyen bildirimleri listele (debug için)
  Future<void> listPendingNotifications() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    print('📋 Bekleyen bildirim sayısı: ${pendingNotifications.length}');
    for (final notification in pendingNotifications) {
      print('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }
}