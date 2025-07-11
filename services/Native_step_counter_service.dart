// lib/services/native_step_counter_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Sadece SystemChannels için tutuldu
import 'package:shared_preferences/shared_preferences.dart';

class NativeStepCounterService extends ChangeNotifier {
  static final NativeStepCounterService _instance = NativeStepCounterService._internal();
  factory NativeStepCounterService() => _instance;
  NativeStepCounterService._internal();

  // Platform Channels (Artık EventChannel kullanılmayacak)
  static const MethodChannel _methodChannel = MethodChannel('com.formdakal/native_step_counter');
  
  // Adım verileri
  int _dailySteps = 0;
  int _totalSteps = 0;
  int _baseStepCount = 0; // Native servisin başlangıç adımı
  bool _isActive = false;
  bool _isNativeSensorAvailable = false;
  DateTime _todayDate = DateTime.now(); // Native tarafından yönetilen gün başlangıcı

  Timer? _updateTimer; // Periyodik güncelleme için timer

  // SharedPreferences anahtarları (Kotlin servisi ile aynı olmalı)
  static const String _keyDailySteps = "daily_steps";
  static const String _keyTotalSteps = "total_steps";
  static const String _keyInitialCount = "initial_count";
  static const String _keyLastDate = "last_date";

  // dailySteps getter'ı
  int get dailySteps => _dailySteps;


  /// Native adım sayacı servisini başlat
  Future<void> initialize() async {
    try {
      print('🚀 Native step counter service başlatılıyor...');
      
      // Native sensör mevcudiyetini kontrol et
      _isNativeSensorAvailable = await _checkNativeSensorAvailability();
      
      if (!_isNativeSensorAvailable) {
        print('❌ Native TYPE_STEP_COUNTER sensörü bulunamadı');
        _isActive = false;
        notifyListeners();
        return;
      }
      
      // Kaydedilmiş verileri yükle (ilk yükleme)
      await _loadSavedData();
      
      // Native arka plan servisini başlat
      await _startBackgroundService();
      
      _isActive = true;
      notifyListeners();
      
      // Periyodik olarak adım verilerini güncelle
      _startUpdateTimer();
      
      print('✅ Native step counter başarıyla başlatıldı');
      print('📊 Mevcut günlük adım (init): $_dailySteps');
      
    } catch (e) {
      print('❌ Native step counter başlatma hatası: $e');
      _isActive = false;
      notifyListeners();
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

  /// Background service başlat (START_STICKY)
  Future<void> _startBackgroundService() async {
    try {
      await _methodChannel.invokeMethod('startBackgroundService');
      print('✅ Background service başlatıldı (START_STICKY)');
    } catch (e) {
      print('❌ Background service başlatma hatası: $e');
    }
  }

  /// Periyodik güncelleme timer'ını başlat
  void _startUpdateTimer() {
    _updateTimer?.cancel(); // Mevcut timer'ı iptal et
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async { // Her 5 saniyede bir güncelle
      await _loadSavedData(); // En güncel veriyi SharedPreferences'tan oku
    });
  }

  /// Manuel günlük adım sıfırlama (Kotlin tarafını tetikler)
  Future<void> resetDailySteps() async {
    try {
      await _methodChannel.invokeMethod('resetDailySteps');
      // Native taraf sıfırladıktan sonra veriyi tekrar yükle
      await _loadSavedData();
      notifyListeners();
      print('🔄 Günlük adımlar manuel olarak sıfırlandı');
    } catch (e) {
      print('❌ Manuel reset hatası: $e');
    }
  }

  /// Servisi durdur (Kotlin tarafını tetikler)
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stopStepCounter');
      await _methodChannel.invokeMethod('stopBackgroundService');
      
      _updateTimer?.cancel(); // Timer'ı durdur
      _isActive = false;
      notifyListeners();
      
      print('🛑 Native step counter durduruldu');
    } catch (e) {
      print('❌ Durdurma hatası: $e');
    }
  }

  /// Anlık adım verilerini al (Kotlin tarafından değil, Flutter'ın kendi state'inden)
  Future<Map<String, int>> getCurrentStepData() async {
    return {
      'dailySteps': _dailySteps,
      'totalSteps': _totalSteps,
    };
  }

  /// Kaydedilmiş veriyi yükleme (Kotlin tarafından kaydedilen veriyi okur)
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance(); // Varsayılan SharedPreferences'ı kullan

      final String? lastDateFromKotlin = prefs.getString(_keyLastDate);
      final String todayKey = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

      if (lastDateFromKotlin != todayKey) {
        _dailySteps = 0;
        _baseStepCount = prefs.getInt(_keyTotalSteps) ?? 0;
        _todayDate = DateTime.now();
      } else {
        _dailySteps = prefs.getInt(_keyDailySteps) ?? 0;
        _baseStepCount = prefs.getInt(_keyInitialCount) ?? 0;
        _todayDate = DateTime.parse(lastDateFromKotlin ?? DateTime.now().toIso8601String());
      }
      
      _totalSteps = prefs.getInt(_keyTotalSteps) ?? 0;
      
      notifyListeners();
      
      print('📂 Native veri yüklendi (Flutter): Günlük=$_dailySteps, Toplam=$_totalSteps');
      
    } catch (e) {
      print('❌ Veri yükleme hatası (Flutter): $e');
    }
  }

  /// Belirli tarih için adım sayısını al (Kotlin tarafından kaydedilen veriyi okur)
  Future<int> getStepsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastDateFromKotlin = prefs.getString(_keyLastDate);
      final String todayKey = '${date.year}-${date.month}-${date.day}';

      if (lastDateFromKotlin == todayKey) {
        return prefs.getInt(_keyDailySteps) ?? 0;
      } else {
        return 0;
      }
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

  /// Test fonksiyonu (geliştirme amaçlı)
  void addTestStep() {
    _dailySteps++;
    _totalSteps++;
    notifyListeners();
    print('🧪 Test adımı eklendi: $_dailySteps');
  }

  /// Debug bilgileri
  Map<String, dynamic> getDebugInfo() {
    return {
      'isActive': _isActive,
      'isNativeSensorAvailable': _isNativeSensorAvailable,
      'dailySteps': _dailySteps,
      'totalSteps': _totalSteps,
      'baseStepCount': _baseStepCount,
      'todayDate': _todayDate.toString(),
    };
  }

  @override
  void dispose() {
    _updateTimer?.cancel(); // Timer'ı temizle
    print('🛑 NativeStepCounterService dispose çağrıldı');
    super.dispose();
  }
}
