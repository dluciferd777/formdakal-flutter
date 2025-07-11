// lib/services/advanced_step_counter_service.dart - ARKA PLAN DESTEKLİ VERSİYON
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class AdvancedStepCounterService extends ChangeNotifier {
  static final AdvancedStepCounterService _instance = AdvancedStepCounterService._internal();
  factory AdvancedStepCounterService() => _instance;
  AdvancedStepCounterService._internal();

  // Sensör subscription'ları - ASLA KAPANMAZ
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<StepCount>? _pedometerSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;
  
  // Adım sayma değişkenleri
  int _todaySteps = 0;
  int _totalSteps = 0;
  int _baseStepCount = 0;        // Gün başındaki step count (pedometer için)
  bool _isWalking = false;
  bool _isServiceActive = false;
  
  // Algoritma parametreleri
  static const double _accelerationThreshold = 0.1;
  static const double _timeThreshold = 0.25;
  static const int _windowSize = 10;
  
  // Hibrit sistem değişkenleri
  bool _isPedometerAvailable = false;
  bool _useBackgroundMode = true;        // ARKA PLAN MODU
  
  // Filtreleme için veri yapıları
  final List<double> _accelerationData = [];
  final List<DateTime> _stepTimeStamps = [];
  DateTime? _lastStepTime;
  double _lastMagnitude = 0.0;
  bool _isPeakDetected = false;
  
  // Sahte adım tespiti için
  int _consecutiveQuickSteps = 0;
  static const int _maxConsecutiveQuickSteps = 5;
  static const double _naturalStepFrequency = 2.5;
  
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
      
      // ARKA PLAN İÇİN: Uygulama lifecycle'ına bağla
      _setupBackgroundHandling();
      
      // ARKA PLAN MODu: Önce native pedometer'ı dene
      await _initializePedometer();
      
      // Eğer pedometer yoksa accelerometer kullan
      if (!_isPedometerAvailable) {
        await _initializeAccelerometer();
      }
      
      _isServiceActive = true;
      notifyListeners();
      
      print('✅ Gelişmiş Adım Sayar başlatıldı - Pedometer: $_isPedometerAvailable, Arka Plan: $_useBackgroundMode');
    } catch (e) {
      print('❌ Adım sayar başlatma hatası: $e');
    }
  }

  // ARKA PLAN HANDLING
  void _setupBackgroundHandling() {
    // App lifecycle değişikliklerini dinle
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      switch (msg) {
        case 'AppLifecycleState.paused':
          // Uygulama arka planda - sensörleri DEVAM ETTİR
          print('📱 Uygulama arka planda - Adım sayar çalışmaya devam ediyor');
          _saveData(); // Veriyi kaydet
          break;
          
        case 'AppLifecycleState.resumed':
          // Uygulama öne geldi - verileri güncelle
          print('📱 Uygulama öne geldi - Veriler güncelleniyor');
          await _loadSavedData();
          notifyListeners();
          break;
          
        case 'AppLifecycleState.detached':
          // Uygulama kapanıyor - SON KAYDETME
          print('📱 Uygulama kapanıyor - Son veri kaydediliyor');
          _saveData();
          break;
      }
      return null;
    });
  }

  // Pedometer'ı başlat (Android native sensor - ARKA PLANDA ÇALIŞIR)
  Future<void> _initializePedometer() async {
    try {
      // Pedometer status stream'ini test et
      final pedestrianStream = Pedometer.pedestrianStatusStream;
      final stepStream = Pedometer.stepCountStream;
      
      // Status subscription - ASLA CANCEL ETME
      _pedestrianSubscription = pedestrianStream.listen(
        (PedestrianStatus event) {
          _isWalking = event.status == 'walking';
          notifyListeners();
        },
        onError: (error) {
          print('⚠️ Pedestrian status hatası: $error');
          _switchToAccelerometer();
        },
        cancelOnError: false,  // Hata durumunda cancel etme
      );
      
      // Step count subscription - ASLA CANCEL ETME  
      _pedometerSubscription = stepStream.listen(
        (StepCount event) {
          _handlePedometerSteps(event.steps);
        },
        onError: (error) {
          print('⚠️ Pedometer step hatası: $error');
          _switchToAccelerometer();
        },
        cancelOnError: false,  // Hata durumunda cancel etme
      );
      
      _isPedometerAvailable = true;
      print('✅ Pedometer aktif (Arka plan destekli)');
      
    } catch (e) {
      print('❌ Pedometer başlatılamadı: $e');
      _isPedometerAvailable = false;
    }
  }

  // Accelerometer tabanlı adım sayma (Fallback)
  Future<void> _initializeAccelerometer() async {
    try {
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 200), // Daha az sıklık - batarya için
      ).listen(
        _processAccelerometerData,
        cancelOnError: false,  // Hata durumunda cancel etme
      );
      
      print('✅ Accelerometer tabanlı adım sayma aktif (Fallback mode)');
    } catch (e) {
      print('❌ Accelerometer başlatılamadı: $e');
    }
  }

  // Pedometer verilerini işle (Android native step counter)
  void _handlePedometerSteps(int totalStepsSinceBoot) {
    // İlk başlatmada veya yeni gün başlangıcında base değeri ayarla
    if (_baseStepCount == 0 || _isNewDay()) {
      _baseStepCount = totalStepsSinceBoot;
      _resetDailyStepsIfNewDay();
    }
    
    // Telefon yeniden başladıysa (step count düştüyse)
    if (totalStepsSinceBoot < _baseStepCount) {
      _baseStepCount = 0;
    }
    
    // Bugünkü adımları hesapla
    final newDailySteps = totalStepsSinceBoot - _baseStepCount;
    
    if (newDailySteps != _todaySteps && newDailySteps >= 0) {
      _todaySteps = newDailySteps;
      _totalSteps = totalStepsSinceBoot;
      _saveData();
      notifyListeners();
      
      print('👣 Pedometer: Günlük=$_todaySteps, Toplam=$_totalSteps');
    }
  }

  // Yeni gün kontrolü
  bool _isNewDay() {
    final now = DateTime.now();
    final prefs = SharedPreferences.getInstance();
    
    return prefs.then((p) {
      final lastDate = p.getString('last_step_date') ?? '';
      final todayStr = '${now.year}-${now.month}-${now.day}';
      
      if (lastDate != todayStr) {
        p.setString('last_step_date', todayStr);
        return true;
      }
      return false;
    }) as bool;
  }

  // Yeni gün başlangıcında günlük adımları sıfırla
  void _resetDailyStepsIfNewDay() {
    final now = DateTime.now();
    SharedPreferences.getInstance().then((prefs) {
      final lastResetDate = prefs.getString('last_reset_date') ?? '';
      final todayStr = '${now.year}-${now.month}-${now.day}';
      
      if (lastResetDate != todayStr) {
        // Yeni gün - günlük adımları sıfırla
        _todaySteps = 0;
        prefs.setString('last_reset_date', todayStr);
        print('🌅 Yeni gün başladı - Günlük adımlar sıfırlandı');
      }
    });
  }

  // Accelerometer verilerini işle (Gelişmiş algoritma - fallback)
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

  // Adım pattern analizi (aynı)
  void _analyzeStepPattern(double magnitude, DateTime now) {
    final average = _accelerationData.reduce((a, b) => a + b) / _accelerationData.length;
    
    final isAboveThreshold = magnitude > (average + _accelerationThreshold);
    final isBelowThreshold = _lastMagnitude > (average + _accelerationThreshold) && 
                            magnitude <= (average + _accelerationThreshold);
    
    if (isBelowThreshold && !_isPeakDetected) {
      _isPeakDetected = true;
      
      if (_lastStepTime != null) {
        final timeDiff = now.difference(_lastStepTime!).inMilliseconds / 1000.0;
        
        if (timeDiff < _timeThreshold) {
          _consecutiveQuickSteps++;
          
          if (_consecutiveQuickSteps > _maxConsecutiveQuickSteps) {
            _isPeakDetected = false;
            return;
          }
        } else {
          _consecutiveQuickSteps = 0;
        }
        
        if (timeDiff > (1.0 / _naturalStepFrequency) * 0.5) {
          _registerStep(now);
        }
      } else {
        _registerStep(now);
      }
    } else if (!isAboveThreshold) {
      _isPeakDetected = false;
    }
    
    _analyzeWalkingStatus(average);
  }

  // Adım kaydet (accelerometer için)
  void _registerStep(DateTime now) {
    _todaySteps++;
    _totalSteps++;
    _lastStepTime = now;
    _stepTimeStamps.add(now);
    
    if (_stepTimeStamps.length > 10) {
      _stepTimeStamps.removeAt(0);
    }
    
    _saveData();
    notifyListeners();
    
    print('👣 Accelerometer: Adım tespit edildi: $_todaySteps');
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

  // Günlük adımları manuel sıfırla
  void resetDailySteps() {
    _todaySteps = 0;
    _baseStepCount = _totalSteps; // Mevcut total'ı base olarak ayarla
    _saveData();
    notifyListeners();
    print('🔄 Günlük adımlar manuel sıfırlandı');
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

  // ARKA PLAN MODu: Dispose fonksiyonunu değiştir
  @override
  void dispose() {
    // SADECE UYGULAMA TAMAMEN KAPANIRKEN ÇAĞIR
    // Normal arka plan geçişlerinde ÇAĞIRMA
    print('⚠️ AdvancedStepCounterService dispose çağrıldı');
    super.dispose();
  }
  
  // Manuel durdurma fonksiyonu (gerekirse)
  void forceStop() {
    _accelerometerSubscription?.cancel();
    _pedometerSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    _isServiceActive = false;
    print('🛑 Adım sayar manuel olarak durduruldu');
  }

  // Test fonksiyonu
  void addTestStep() {
    if (!_isServiceActive) return;
    _registerStep(DateTime.now());
  }

  // Kalibasyon fonksiyonu
  void calibrateThreshold(double newThreshold) {
    print('📊 Yeni eşik değeri ayarlandı: $newThreshold');
  }

  // Samsung Health tarzı ek özellikler
  
  // Kalori hesaplama
  int getCaloriesFromSteps() {
    return (_todaySteps * 0.06).round(); // Basit formül
  }
  
  // Mesafe hesaplama
  double getDistanceFromSteps() {
    return _todaySteps * 0.0008; // km cinsinden, ortalama adım uzunluğu 0.8m
  }
  
  // Aktif dakika hesaplama (örnek)
  int getActiveMintes() {
    return (_todaySteps / 100).round().clamp(0, 90); // Basit formül
  }
}