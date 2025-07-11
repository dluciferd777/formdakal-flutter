// lib/services/notification_service.dart - HATALAR DÜZELTİLDİ
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
  
  // Bildirim ID'leri
  static const int _stepReminderID = 1000;
  static const int _workoutReminderID = 1001;
  static const int _waterReminderID = 1002;
  // _customReminderBaseID kaldırıldı - kullanılmıyordu

  Future<void> init() async {
    try {
      if (_isInitialized) {
        print('✅ Bildirim servisi zaten başlatılmış');
        return;
      }

      _prefs = await SharedPreferences.getInstance();
      
      // Timezone başlatma
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      final bool? initialized = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          print('🔔 Bildirime tıklandı: ${response.payload}');
          await _handleNotificationTap(response);
        },
      );

      if (initialized == true) {
        await _requestPermissions();
        await _setupAutomaticReminders();
        
        _isInitialized = true;
        print('✅ Bildirim servisi başarıyla başlatıldı');
      } else {
        print('⚠️ Bildirim servisi başlatılamadı');
      }
      
    } catch (e, stackTrace) {
      print('❌ Bildirim servisi başlatma hatası: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        print('📱 Bildirim izni durumu: $status');
      }
      
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        print('⏰ Alarm izni durumu: $status');
      }
    } catch (e) {
      print('⚠️ İzin isteme hatası: $e');
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

  // DÜZELTİLDİ: schedule yerine zonedSchedule kullanıldı
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Bildirim servisi henüz başlatılmamış');
      return;
    }

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
      // DÜZELTİLDİ: zonedSchedule kullanıldı
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

  Future<void> _setupAutomaticReminders() async {
    try {
      await _scheduleStepReminder();
      await _scheduleWorkoutReminder();
      await _scheduleWaterReminders();
      
      print('✅ Otomatik hatırlatmalar ayarlandı');
    } catch (e) {
      print('❌ Otomatik hatırlatma hatası: $e');
    }
  }

  Future<void> _scheduleStepReminder() async {
    try {
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
    } catch (e) {
      print('❌ Adım hatırlatması hatası: $e');
    }
  }

  Future<void> _scheduleWorkoutReminder() async {
    try {
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
    } catch (e) {
      print('❌ Egzersiz hatırlatması hatası: $e');
    }
  }

  Future<void> _scheduleWaterReminders() async {
    try {
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
    } catch (e) {
      print('❌ Su hatırlatması hatası: $e');
    }
  }

  Future<void> sendMotivationNotification(String type) async {
    if (!_isInitialized) return;

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

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Bildirim servisi başlatılmamış - anında bildirim gösterilemiyor');
      return;
    }

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

  Future<void> toggleReminderType(String type, bool isEnabled) async {
    try {
      await _prefs.setBool('${type}_reminder_enabled', isEnabled);
      
      if (isEnabled) {
        await _setupAutomaticReminders();
        print('✅ $type hatırlatması etkinleştirildi');
      } else {
        await _cancelReminderType(type);
        print('❌ $type hatırlatması devre dışı bırakıldı');
      }
    } catch (e) {
      print('❌ Hatırlatma ayar hatası: $e');
    }
  }

  Future<void> _cancelReminderType(String type) async {
    try {
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
    } catch (e) {
      print('❌ Hatırlatma iptal hatası: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.cancel(id);
      print('🗑️ Bildirim iptal edildi: ID $id');
    } catch (e) {
      print('❌ Bildirim iptal hatası: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.cancelAll();
      print('🗑️ Tüm bildirimler iptal edildi');
    } catch (e) {
      print('❌ Tüm bildirim iptal hatası: $e');
    }
  }

  bool isReminderEnabled(String type) {
    try {
      return _prefs.getBool('${type}_reminder_enabled') ?? true;
    } catch (e) {
      print('❌ Hatırlatma ayar okuma hatası: $e');
      return true;
    }
  }

  Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 9999,
      title: '🧪 Test Bildirimi',
      body: 'FormdaKal bildirimleri çalışıyor! ✅',
      payload: 'test',
    );
  }

  bool get isInitialized => _isInitialized;
}