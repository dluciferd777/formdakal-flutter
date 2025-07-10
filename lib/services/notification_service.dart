// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;
  
  // Bildirim ID'leri
  static const int stepReminderID = 1000;
  static const int workoutReminderID = 1001;
  static const int vitaminReminderID = 1002;
  static const int customReminderBaseID = 2000;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Timezone veritabanını başlat
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      
      // Android bildirim kanalları oluştur
      await _createNotificationChannels();
      
      // Bildirim ayarlarını başlat
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // İzinleri iste
      await _requestAllPermissions();
      
      print('✅ Bildirim servisi başlatıldı');
    } catch (e) {
      print('❌ Bildirim servisi başlatma hatası: $e');
    }
  }

  // Android bildirim kanalları oluştur
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Ana kanal - Yüksek öncelik, ses ve titreşim
      final mainChannel = AndroidNotificationChannel(
        'formdakal_main',
        'FormdaKal Hatırlatıcılar',
        description: 'Egzersiz, vitamin ve özel hatırlatıcılar',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
        showBadge: true,
      );

      // Motivasyon kanalı
      final motivationChannel = AndroidNotificationChannel(
        'formdakal_motivation',
        'FormdaKal Motivasyon',
        description: 'Başarı ve motivasyon bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF4CAF50),
      );

      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(motivationChannel);
      
      print('✅ Bildirim kanalları oluşturuldu');
    }
  }

  // Tüm izinleri iste
  Future<void> _requestAllPermissions() async {
    try {
      // Android 13+ için bildirim izni
      final notificationStatus = await Permission.notification.request();
      print('📱 Bildirim izni: $notificationStatus');

      // Tam zamanlanmış alarm izni (Android 12+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        print('⏰ Tam alarm izni: $exactAlarmStatus');
      }

      // Sistem ayarlarında bildirimlerin açık olup olmadığını kontrol et
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled() ?? false;
        print('🔔 Sistem bildirimleri aktif: $areNotificationsEnabled');
        
        if (!areNotificationsEnabled) {
          print('⚠️ Sistem bildirimlerini açın! Ayarlar > Uygulamalar > FormdaKal > Bildirimler');
        }
      }
    } catch (e) {
      print('❌ İzin isteme hatası: $e');
    }
  }

  // Bildirime tıklama işlemi
  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    print('🔔 Bildirime tıklandı: $payload');
    
    // Burada navigation yapabilirsiniz
    switch (payload) {
      case 'step_reminder':
        // Adım detay sayfasına git
        break;
      case 'workout_reminder':
        // Egzersiz sayfasına git
        break;
      case 'vitamin_reminder':
        // Hatırlatıcılar sayfasına git
        break;
    }
  }

  // Ana bildirim zamanlama fonksiyonu - SESLİ VE TİTREŞİMLİ
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Geçmiş zaman kontrolü
    if (scheduledTime.isBefore(DateTime.now())) {
      print('⚠️ Geçmiş zamana bildirim zamanlanamaz: $scheduledTime');
      return;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_main',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Egzersiz, vitamin ve özel hatırlatıcılar',
      importance: Importance.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // SES VE TİTREŞİM AKTİF
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Bildirim stilleri
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      // Kalıcı bildirim
      ongoing: false,
      autoCancel: true,
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('✅ Sesli & Titreşimli bildirim zamanlandı: $title - $scheduledTime');
    } catch (e) {
      print('❌ Bildirim zamanlama hatası: $e');
    }
  }

  // ANINDA sesli ve titreşimli bildirim gönder
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isUrgent = true,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'formdakal_main',
      'FormdaKal Hatırlatıcılar',
      channelDescription: 'Anında bildirimler',
      importance: Importance.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // GÜÇLÜ SES VE TİTREŞİM
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF4CAF50),
      // Büyük metin stili
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      ongoing: false,
      autoCancel: true,
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
      
      print('✅ Anında sesli bildirim gönderildi: $title');
    } catch (e) {
      print('❌ Anında bildirim hatası: $e');
    }
  }

  // VİTAMİN HATIRLATMASI - Özel sesli ve titreşimli
  Future<void> scheduleVitaminReminder({
    required int id,
    required String vitaminName,
    required DateTime scheduledTime,
  }) async {
    await scheduleNotification(
      id: id,
      title: '💊 Vitamin Zamanı!',
      body: '$vitaminName almanın zamanı geldi. Sağlığın için önemli!',
      scheduledTime: scheduledTime,
      payload: 'vitamin_reminder',
    );
  }

  // SPOR HATIRLATMASI - Motivasyonel sesli bildirim
  Future<void> scheduleWorkoutReminder({
    required int id,
    required String workoutType,
    required DateTime scheduledTime,
  }) async {
    final motivationalMessages = [
      'Kas yapmak istiyorsan, kalk ve harekete geç! 💪',
      'Güçlü vücut, güçlü karakter! Sporunu yap! 🔥',
      'Hedeflerine ulaşmak için şimdi çalışma zamanı! ⚡',
      'Vücudun sana teşekkür edecek. Başla! 🚀',
      'Erteleme zamanı değil, aksiyon zamanı! 💯',
    ];
    
    final randomMessage = motivationalMessages[Random().nextInt(motivationalMessages.length)];
    
    await scheduleNotification(
      id: id,
      title: '🏋️ $workoutType Zamanı!',
      body: randomMessage,
      scheduledTime: scheduledTime,
      payload: 'workout_reminder',
    );
  }

  // ADIM HATIRLATMASI - Günlük hedef odaklı
  Future<void> scheduleStepReminder({
    required int id,
    required int currentSteps,
    required int targetSteps,
    required DateTime scheduledTime,
  }) async {
    final remaining = targetSteps - currentSteps;
    String message;
    
    if (remaining <= 0) {
      message = 'Tebrikler! Günlük adım hedefinizi aştınız! 🎉';
    } else if (remaining < 1000) {
      message = 'Hedefe çok yakınsınız! Sadece $remaining adım kaldı! 👣';
    } else {
      message = 'Henüz $remaining adım atmanız gerekiyor. Hadi biraz yürüyelim! 🚶‍♂️';
    }
    
    await scheduleNotification(
      id: id,
      title: '👟 Adım Hedefin Nasıl?',
      body: message,
      scheduledTime: scheduledTime,
      payload: 'step_reminder',
    );
  }

  // ÖZEL HATIRLATICI - Kullanıcı tanımlı
  Future<void> scheduleCustomReminder({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? customPayload,
  }) async {
    await scheduleNotification(
      id: id,
      title: title,
      body: message,
      scheduledTime: scheduledTime,
      payload: customPayload ?? 'custom_reminder',
    );
  }

  // TEST BİLDİRİMİ - Ses ve titreşim testi
  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 99999,
      title: '🧪 Test Bildirimi',
      body: 'FormdaKal bildirimleri çalışıyor! Ses ve titreşim aktif ✅',
      payload: 'test',
      isUrgent: true,
    );
  }

  // MOTİVASYON BİLDİRİMİ - Başarı durumlarında
  Future<void> sendMotivationNotification(String type, {Map<String, dynamic>? data}) async {
    String title, body;
    
    switch (type) {
      case 'step_goal_reached':
        final steps = data?['steps'] ?? 10000;
        title = '🎉 Harika! Adım Hedefine Ulaştın!';
        body = 'Bugün $steps adım attın! Muhteşem bir performans! 👏';
        break;
      case 'workout_completed':
        final workoutName = data?['workout'] ?? 'antrenmanını';
        title = '💪 Egzersiz Tamamlandı!';
        body = '$workoutName tamamladın! Kendini ödüllendirmeyi unutma! 🏆';
        break;
      case 'weekly_goal':
        title = '📊 Haftalık Hedef Tamamlandı!';
        body = 'Bu haftaki performansın muhteşem! İlerlemen devam ediyor! 📈';
        break;
      case 'streak_milestone':
        final days = data?['days'] ?? 7;
        title = '🔥 Seri Devam Ediyor!';
        body = '$days gündür hedefe ulaşıyorsun! Bu momentum\'u kaybetme! ⚡';
        break;
      default:
        title = '🎯 Motivasyon';
        body = 'Hedeflerine ulaşmak için bir adım daha! Devam et! 💪';
    }

    await showInstantNotification(
      id: Random().nextInt(10000) + 50000,
      title: title,
      body: body,
      payload: type,
      isUrgent: false,
    );
  }

  // BİLDİRİM DURUMU KONTROLÜ
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  // BEKLEYEN BİLDİRİMLERİ LİSTELE
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // TEKİL BİLDİRİMİ İPTAL ET
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Bildirim iptal edildi: ID $id');
  }

  // TÜM BİLDİRİMLERİ İPTAL ET
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Tüm bildirimler iptal edildi');
  }

  // Bildirim ayarlarını kaydet/yükle
  Future<void> _saveNotificationSettings(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<bool> _getNotificationSetting(String key, {bool defaultValue = true}) async {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  // Bildirim ayarlarını kontrol et
  Future<bool> isNotificationTypeEnabled(String type) async {
    return await _getNotificationSetting('notification_$type');
  }

  // Bildirim türünü aktif/pasif yap
  Future<void> toggleNotificationType(String type, bool enabled) async {
    await _saveNotificationSettings('notification_$type', enabled);
    print('🔔 $type bildirimleri: ${enabled ? "Açık" : "Kapalı"}');
  }

  // AYARLAR SAYFASINI AÇ
  Future<void> openNotificationSettings() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}