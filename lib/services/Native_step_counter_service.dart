// lib/services/native_step_counter_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NativeStepCounterService extends ChangeNotifier {
  static final NativeStepCounterService _instance = NativeStepCounterService._internal();
  factory NativeStepCounterService() => _instance;
  NativeStepCounterService._internal();

  // Platform Channels - Android native ile iletişim
  static const MethodChannel _methodChannel = MethodChannel('com.formdakal/native_step_counter');
  static const EventChannel _eventChannel = EventChannel('com.formdakal/native_step_stream');
  
  // Stream subscription
  StreamSubscription<dynamic>? _nativeStepStream;
  
  // Adım verileri
  int _totalSteps = 0;
  int _dailySteps = 0;
  int _baseStepCount = 0;
  bool _isActive = false;
  bool _isNativeSensorAvailable = false;
  bool _isWalking = false;
  DateTime _lastStepTime = DateTime.now();
  DateTime _todayDate = DateTime.now();
  
  // Getters
  int get totalSteps => _totalSteps;
  int get dailySteps => _dailySteps;
  bool get isActive => _isActive;
  bool get isNativeSensorAvailable => _isNativeSensorAvailable;
  bool get isWalking => _isWalking;

  /// Native adım sayacı servisini başlat
  Future<void> initialize() async {
    try {
      print('🚀 Native step counter service başlatılıyor...');
      
      // Native sensör mevcudiyetini kontrol et
      _isNativeSensorAvailable = await _checkNativeSensorAvailability();
      
      if (!_isNativeSensorAvailable) {
        print('❌ Native TYPE_STEP_COUNTER sensörü bulunamadı');
        return;
      }
      
      // Kaydedilmiş verileri yükle
      await _loadSavedData();
      
      // Native event stream'i dinlemeye başla
      _startNativeEventStream();
      
      // Native step counter'ı başlat
      await _startNativeStepCounter();
      
      // Background service'i başlat
      await _startBackgroundService();
      
      _isActive = true;
      notifyListeners();
      
      print('✅ Native step counter başarıyla başlatıldı');
      print('📊 Mevcut günlük adım: $_dailySteps');
      
    } catch (e) {
      print('❌ Native step counter başlatma hatası: $e');
      _isActive = false;
    }
  }

  /// Native Android sensör mevcudiyetini kontrol et
  Future<bool> _checkNativeSensorAvailability() async {
    try {
      final result = await _methodChannel.invokeMethod('checkSensorAvailability');
      return result['stepCounterAvailable'] == true;
    } catch (e) {
      print('❌ Sensör kontrolü hatası: $e');
      return false;
    }
  }

  /// Native step counter'ı başlat
  Future<void> _startNativeStepCounter() async {
    try {
      await _methodChannel.invokeMethod('startStepCounter');
      print('✅ Native TYPE_STEP_COUNTER sensörü başlatıldı');
    } catch (e) {
      print('❌ Native step counter başlatma hatası: $e');
    }
  }

  /// Background service başlat (START_STICKY)
  Future<void> _startBackgroundService() async {
    try {
      await _methodChannel.invokeMethod('startBackgroundService');
      print('✅ Background service başlatıldı (START_STICKY)');
    } catch (e) {
      print('❌ Background service başlatma hatası: $e');
    }
  }

  /// Native event stream dinlemeyi başlat
  void _startNativeEventStream() {
    _nativeStepStream = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        _handleNativeStepEvent(event);
      },
      onError: (error) {
        print('❌ Native step stream hatası: $error');
      },
      onDone: () {
        print('⚠️ Native step stream kapandı');
      },
    );
  }

  /// Native'den gelen step event'lerini işle
  void _handleNativeStepEvent(dynamic event) {
    if (event is Map<String, dynamic>) {
      final eventType = event['type'] as String?;
      
      switch (eventType) {
        case 'STEP_COUNTER':
          _handleStepCounterEvent(event);
          break;
        case 'STEP_DETECTOR':
          _handleStepDetectorEvent(event);
          break;
        case 'WALKING_STATUS':
          _handleWalkingStatusEvent(event);
          break;
        case 'ERROR':
          _handleErrorEvent(event);
          break;
      }
    }
  }

  /// TYPE_STEP_COUNTER sensöründen gelen veriyi işle
  void _handleStepCounterEvent(Map<String, dynamic> event) {
    final totalStepsSinceBoot = event['totalSteps'] as int? ?? 0;
    final timestamp = event['timestamp'] as int? ?? 0;
    
    // Yeni gün kontrolü
    final eventTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (_isNewDay(eventTime)) {
      _resetForNewDay();
    }
    
    // İlk başlatma: base step count ayarla
    if (_baseStepCount == 0) {
      _baseStepCount = totalStepsSinceBoot;
      print('📊 Base step count ayarlandı: $_baseStepCount');
    }
    
    // Telefon yeniden başladıysa (step count düştü)
    if (totalStepsSinceBoot < _baseStepCount) {
      print('🔄 Telefon yeniden başladı, base sıfırlanıyor');
      _baseStepCount = 0;
    }
    
    // Günlük adımları hesapla
    final newDailySteps = totalStepsSinceBoot - _baseStepCount;
    
    if (newDailySteps != _dailySteps && newDailySteps >= 0) {
      _dailySteps = newDailySteps;
      _totalSteps = totalStepsSinceBoot;
      _lastStepTime = eventTime;
      
      _saveData();
      notifyListeners();
      
      print('👣 Adım güncellendi: Günlük=$_dailySteps, Toplam=$_totalSteps');
    }
  }

  /// TYPE_STEP_DETECTOR sensöründen gelen veriyi işle
  void _handleStepDetectorEvent(Map<String, dynamic> event) {
    final timestamp = event['timestamp'] as int? ?? 0;
    final stepTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    print('👟 Adım tespit edildi: ${stepTime.toString()}');
    
    // Yürüme durumunu güncelle
    _isWalking = true;
    notifyListeners();
    
    // 5 saniye sonra yürüme durumunu false yap
    Timer(const Duration(seconds: 5), () {
      _isWalking = false;
      notifyListeners();
    });
  }

  /// Yürüme durumu değişikliğini işle
  void _handleWalkingStatusEvent(Map<String, dynamic> event) {
    final isWalking = event['isWalking'] as bool? ?? false;
    
    if (_isWalking != isWalking) {
      _isWalking = isWalking;
      notifyListeners();
      print('🚶 Yürüme durumu: ${isWalking ? "Yürüyor" : "Durdu"}');
    }
  }

  /// Hata event'ini işle
  void _handleErrorEvent(Map<String, dynamic> event) {
    final errorMessage = event['message'] as String? ?? 'Bilinmeyen hata';
    print('❌ Native sensör hatası: $errorMessage');
  }

  /// Yeni gün kontrolü
  bool _isNewDay(DateTime eventTime) {
    return eventTime.day != _todayDate.day ||
           eventTime.month != _todayDate.month ||
           eventTime.year != _todayDate.year;
  }

  /// Yeni gün için reset işlemi
  void _resetForNewDay() {
    _dailySteps = 0;
    _baseStepCount = _totalSteps;
    _todayDate = DateTime.now();
    
    _saveData();
    notifyListeners();
    
    print('🌅 Yeni gün başladı, günlük adımlar sıfırlandı');
  }

  /// Manuel günlük adım sıfırlama
  Future<void> resetDailySteps() async {
    try {
      await _methodChannel.invokeMethod('resetDailySteps');
      
      _dailySteps = 0;
      _baseStepCount = _totalSteps;
      _todayDate = DateTime.now();
      
      _saveData();
      notifyListeners();
      
      print('🔄 Günlük adımlar manuel olarak sıfırlandı');
    } catch (e) {
      print('❌ Manuel reset hatası: $e');
    }
  }

  /// Servisi durdur
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stopStepCounter');
      await _methodChannel.invokeMethod('stopBackgroundService');
      
      _nativeStepStream?.cancel();
      _isActive = false;
      notifyListeners();
      
      print('🛑 Native step counter durduruldu');
    } catch (e) {
      print('❌ Durdurma hatası: $e');
    }
  }

  /// Anlık adım verilerini al
  Future<Map<String, int>> getCurrentStepData() async {
    try {
      final result = await _methodChannel.invokeMethod('getCurrentStepData');
      return {
        'dailySteps': result['dailySteps'] ?? _dailySteps,
        'totalSteps': result['totalSteps'] ?? _totalSteps,
      };
    } catch (e) {
      print('❌ Anlık veri alma hatası: $e');
      return {
        'dailySteps': _dailySteps,
        'totalSteps': _totalSteps,
      };
    }
  }

  /// Veri kaydetme
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setInt('native_daily_steps_$todayKey', _dailySteps);
      await prefs.setInt('native_total_steps', _totalSteps);
      await prefs.setInt('native_base_step_count', _baseStepCount);
      await prefs.setString('native_today_date', _todayDate.toIso8601String());
      
    } catch (e) {
      print('❌ Veri kaydetme hatası: $e');
    }
  }

  /// Kaydedilmiş veriyi yükleme
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      _dailySteps = prefs.getInt('native_daily_steps_$todayKey') ?? 0;
      _totalSteps = prefs.getInt('native_total_steps') ?? 0;
      _baseStepCount = prefs.getInt('native_base_step_count') ?? 0;
      
      final todayDateString = prefs.getString('native_today_date');
      if (todayDateString != null) {
        _todayDate = DateTime.parse(todayDateString);
      }
      
      print('📂 Native veri yüklendi: Günlük=$_dailySteps, Toplam=$_totalSteps');
      
    } catch (e) {
      print('❌ Veri yükleme hatası: $e');
    }
  }

  /// Belirli tarih için adım sayısını al
  Future<int> getStepsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      return prefs.getInt('native_daily_steps_$dateKey') ?? 0;
    } catch (e) {
      print('❌ Tarih için adım alma hatası: $e');
      return 0;
    }
  }

  /// Haftalık istatistik
  Future<Map<DateTime, int>> getWeeklyStats() async {
    final Map<DateTime, int> weeklyData = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = await getStepsForDate(date);
      weeklyData[DateTime(date.year, date.month, date.day)] = steps;
    }
    
    return weeklyData;
  }

  /// Hesaplanmış veriler

  // Kalori hesaplama (daha hassas)
  double getCaloriesFromSteps() {
    return _dailySteps * 0.045; // Geliştirilmiş kalori hesabı
  }

  // Mesafe hesaplama (metre cinsinden)
  double getDistanceFromSteps() {
    return _dailySteps * 0.762; // metre cinsinden
  }

  // Kilometre cinsinden mesafe
  double getDistanceInKm() {
    return getDistanceFromSteps() / 1000;
  }

  // Aktif dakika hesaplama
  int getActiveMinutes() {
    return (_dailySteps / 120).round().clamp(0, 1440); // 120 adım = 1 dakika
  }

  // Ortalama hız (yürüyor ise)
  double getAverageSpeed() {
    if (_isWalking) {
      return 4.8; // km/h - normal yürüme hızı
    }
    return 0.0;
  }

  @override
  void dispose() {
    _nativeStepStream?.cancel();
    super.dispose();
  }

  /// Test fonksiyonu (geliştirme amaçlı)
  void addTestStep() {
    _dailySteps++;
    _totalSteps++;
    _saveData();
    notifyListeners();
    print('🧪 Test adımı eklendi: $_dailySteps');
  }

  /// Debug bilgileri
  Map<String, dynamic> getDebugInfo() {
    return {
      'isActive': _isActive,
      'isNativeSensorAvailable': _isNativeSensorAvailable,
      'isWalking': _isWalking,
      'dailySteps': _dailySteps,
      'totalSteps': _totalSteps,
      'baseStepCount': _baseStepCount,
      'lastStepTime': _lastStepTime.toString(),
      'todayDate': _todayDate.toString(),
    };
  }
}