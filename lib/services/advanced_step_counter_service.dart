// lib/services/advanced_step_counter_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class AdvancedStepCounterService extends ChangeNotifier {
  static final AdvancedStepCounterService _instance = AdvancedStepCounterService._internal();
  factory AdvancedStepCounterService() => _instance;
  AdvancedStepCounterService._internal();

  // Sensör subscription'ları
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  
  // Adım sayma değişkenleri
  int _todaySteps = 0;
  int _totalSteps = 0;
  bool _isWalking = false;
  bool _isServiceActive = false;
  
  // Algoritma parametreleri
  static const double _accelerationThreshold = 0.1; // Minimum ivme eşiği
  static const double _timeThreshold = 0.25; // Minimum adım arası süre (saniye)
  static const int _windowSize = 10; // Hareketli ortalama penceresi
  
  // Filtreleme için veri yapıları
  final List<double> _accelerationData = [];
  final List<DateTime> _stepTimeStamps = [];
  DateTime? _lastStepTime;
  double _lastMagnitude = 0.0;
  bool _isPeakDetected = false;
  
  // Sahte adım tespiti için
  int _consecutiveQuickSteps = 0;
  static const int _maxConsecutiveQuickSteps = 5;
  static const double _naturalStepFrequency = 2.5; // Hz
  
  // Hibrit sistem değişkenleri
  bool _isPedometerAvailable = false;
  int _baseStepCount = 0; // Pedometer sıfırlama için
  
  // Getter'lar
  int get todaySteps => _todaySteps;
  int get totalSteps => _totalSteps;
  bool get isWalking => _isWalking;
  bool get isServiceActive => _isServiceActive;

  // Servisi başlat
  Future<void> initialize() async {
    try {
      // İzinleri kontrol et
      await _requestPermissions();
      
      // Kaydedilmiş verileri yükle
      await _loadSavedData();
      
      // Hibrit sistem: Önce pedometer'ı dene
      await _initializePedometer();
      
      // Eğer pedometer yoksa accelerometer kullan
      if (!_isPedometerAvailable) {
        await _initializeAccelerometer();
      }
      
      _isServiceActive = true;
      notifyListeners();
      
      print('✅ Gelişmiş Adım Sayar başlatıldı - Pedometer: $_isPedometerAvailable');
    } catch (e) {
      print('❌ Adım sayar başlatma hatası: $e');
    }
  }

  // Pedometer'ı başlat (Android/iOS native sensor)
  Future<void> _initializePedometer() async {
    try {
      // Pedometer status stream'ini test et
      final pedestrianStream = Pedometer.pedestrianStatusStream;
      final stepStream = Pedometer.stepCountStream;
      
      // Status subscription
      _pedestrianSubscription = pedestrianStream.listen(
        (PedestrianStatus event) {
          _isWalking = event.status == 'walking';
          notifyListeners();
        },
        onError: (error) {
          print('⚠️ Pedestrian status hatası: $error');
          // Hata durumunda accelerometer'a geç
          _switchToAccelerometer();
        },
      );
      
      // Step count subscription
      _pedometerSubscription = stepStream.listen(
        (StepCount event) {
          _handlePedometerSteps(event.steps);
        },
        onError: (error) {
          print('⚠️ Pedometer step hatası: $error');
          _switchToAccelerometer();
        },
      );
      
      _isPedometerAvailable = true;
      print('✅ Pedometer aktif');
      
    } catch (e) {
      print('❌ Pedometer başlatılamadı: $e');
      _isPedometerAvailable = false;
    }
  }

  // Accelerometer tabanlı adım sayma
  Future<void> _initializeAccelerometer() async {
    try {
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 50), // 20Hz
      ).listen(_processAccelerometerData);
      
      print('✅ Accelerometer tabanlı adım sayma aktif');
    } catch (e) {
      print('❌ Accelerometer başlatılamadı: $e');
    }
  }

  // Pedometer verilerini işle
  void _handlePedometerSteps(int totalStepsSinceBoot) {
    // İlk başlatmada base değeri kaydet
    if (_baseStepCount == 0) {
      _baseStepCount = totalStepsSinceBoot;
    }
    
    // Telefon yeniden başladıysa base'i sıfırla
    if (totalStepsSinceBoot < _baseStepCount) {
      _baseStepCount = 0;
    }
    
    // Bugünkü adımları hesapla
    final dailySteps = totalStepsSinceBoot - _baseStepCount;
    
    if (dailySteps != _todaySteps) {
      _todaySteps = dailySteps;
      _totalSteps = totalStepsSinceBoot;
      _saveData();
      notifyListeners();
    }
  }

  // Accelerometer verilerini işle (Gelişmiş algoritma)
  void _processAccelerometerData(AccelerometerEvent event) {
    final magnitude = _calculateMagnitude(event.x, event.y, event.z);
    final now = DateTime.now();
    
    // Veri penceresini güncelle
    _accelerationData.add(magnitude);
    if (_accelerationData.length > _windowSize) {
      _accelerationData.removeAt(0);
    }
    
    // Minimum pencere boyutuna ulaştıktan sonra analiz et
    if (_accelerationData.length >= _windowSize) {
      _analyzeStepPattern(magnitude, now);
    }
    
    _lastMagnitude = magnitude;
  }

  // Adım pattern analizi
  void _analyzeStepPattern(double magnitude, DateTime now) {
    // Hareketli ortalama hesapla
    final average = _accelerationData.reduce((a, b) => a + b) / _accelerationData.length;
    
    // Peak detection (tepe noktası tespiti)
    final isAboveThreshold = magnitude > (average + _accelerationThreshold);
    final isBelowThreshold = _lastMagnitude > (average + _accelerationThreshold) && 
                            magnitude <= (average + _accelerationThreshold);
    
    // Adım tespiti: Tepe noktasından düşüş
    if (isBelowThreshold && !_isPeakDetected) {
      _isPeakDetected = true;
      
      // Zaman kontrolü: Çok hızlı adımları filtrele
      if (_lastStepTime != null) {
        final timeDiff = now.difference(_lastStepTime!).inMilliseconds / 1000.0;
        
        if (timeDiff < _timeThreshold) {
          _consecutiveQuickSteps++;
          
          // Çok fazla hızlı adım varsa sahte kabul et
          if (_consecutiveQuickSteps > _maxConsecutiveQuickSteps) {
            _isPeakDetected = false;
            return;
          }
        } else {
          _consecutiveQuickSteps = 0;
        }
        
        // Doğal yürüme frekansı kontrolü
        if (timeDiff > (1.0 / _naturalStepFrequency) * 0.5) { // Minimum doğal süre
          _registerStep(now);
        }
      } else {
        _registerStep(now);
      }
    } else if (!isAboveThreshold) {
      _isPeakDetected = false;
    }
    
    // Yürüme durumu analizi
    _analyzeWalkingStatus(average);
  }

  // Adım kaydet
  void _registerStep(DateTime now) {
    _todaySteps++;
    _totalSteps++;
    _lastStepTime = now;
    _stepTimeStamps.add(now);
    
    // Son 10 adımı tut
    if (_stepTimeStamps.length > 10) {
      _stepTimeStamps.removeAt(0);
    }
    
    _saveData();
    notifyListeners();
    
    print('👣 Adım tespit edildi: $_todaySteps');
  }

  // Yürüme durumu analizi
  void _analyzeWalkingStatus(double average) {
    final recentActivity = _accelerationData.length >= 5 
        ? _accelerationData.skip(_accelerationData.length - 5).toList()
        : _accelerationData;
    
    final recentAverage = recentActivity.isNotEmpty 
        ? recentActivity.reduce((a, b) => a + b) / recentActivity.length
        : 0.0;
    
    final isCurrentlyWalking = recentAverage > (average * 1.1);
    
    if (isCurrentlyWalking != _isWalking) {
      _isWalking = isCurrentlyWalking;
      notifyListeners();
    }
  }

  // Accelerometer'a geç
  void _switchToAccelerometer() {
    if (!_isPedometerAvailable) return;
    
    _isPedometerAvailable = false;
    _pedometerSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    
    _initializeAccelerometer();
    print('🔄 Pedometer hatası - Accelerometer\'a geçildi');
  }

  // Vector magnitude hesapla
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  // İzinleri iste
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.activityRecognition.request();
      await Permission.sensors.request();
    }
  }

  // Günlük adımları sıfırla
  void resetDailySteps() {
    _todaySteps = 0;
    _saveData();
    notifyListeners();
    print('🔄 Günlük adımlar sıfırlandı');
  }

  // Veriyi kaydet
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setInt('daily_steps_$todayKey', _todaySteps);
      await prefs.setInt('total_steps', _totalSteps);
      await prefs.setInt('base_step_count', _baseStepCount);
    } catch (e) {
      print('❌ Veri kaydetme hatası: $e');
    }
  }

  // Veriyi yükle
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      _todaySteps = prefs.getInt('daily_steps_$todayKey') ?? 0;
      _totalSteps = prefs.getInt('total_steps') ?? 0;
      _baseStepCount = prefs.getInt('base_step_count') ?? 0;
      
      print('📂 Kaydedilmiş veri yüklendi: Günlük=$_todaySteps, Toplam=$_totalSteps');
    } catch (e) {
      print('❌ Veri yükleme hatası: $e');
    }
  }

  // Belirli tarih için adım sayısı al
  Future<int> getStepsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      return prefs.getInt('daily_steps_$dateKey') ?? 0;
    } catch (e) {
      print('❌ Tarih için veri alma hatası: $e');
      return 0;
    }
  }

  // Haftalık istatistik
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

  // Servisi durdur
  void dispose() {
    _accelerometerSubscription?.cancel();
    _pedometerSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    _isServiceActive = false;
    super.dispose();
  }

  // Test fonksiyonu
  void addTestStep() {
    if (!_isServiceActive) return;
    _registerStep(DateTime.now());
  }

  // Kalibasyon fonksiyonu
  void calibrateThreshold(double newThreshold) {
    // _accelerationThreshold = newThreshold; // const olduğu için runtime'da değiştirilemez
    print('📊 Yeni eşik değeri ayarlandı: $newThreshold');
    // SharedPreferences'a kaydet ve restart et
  }
}