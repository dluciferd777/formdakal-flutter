// lib/screens/step_details_screen.dart - GPS EKLİ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/advanced_step_counter_service.dart';
import '../utils/colors.dart';

class StepDetailsScreen extends StatefulWidget {
  const StepDetailsScreen({super.key});

  @override
  State<StepDetailsScreen> createState() => _StepDetailsScreenState();
}

class _StepDetailsScreenState extends State<StepDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // GPS Tracking
  StreamSubscription<Position>? _positionStream;
  List<Position> _routePoints = [];
  bool _isTracking = false;
  double _totalDistance = 0.0;
  DateTime? _trackingStartTime;
  Duration _trackingDuration = Duration.zero;
  Timer? _durationTimer;
  
  // Tracking stats
  double _currentSpeed = 0.0; // m/s
  double _averageSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _calories = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stopTracking();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum izni gerekli')),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum izni ayarlardan açılmalı')),
      );
      return;
    }
  }

  void _startTracking() async {
    if (_isTracking) return;
    
    try {
      setState(() {
        _isTracking = true;
        _trackingStartTime = DateTime.now();
        _routePoints.clear();
        _totalDistance = 0.0;
        _currentSpeed = 0.0;
        _averageSpeed = 0.0;
        _maxSpeed = 0.0;
        _calories = 0.0;
        _trackingDuration = Duration.zero;
      });

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 5 metre değişiklik
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _updateLocation(position);
        },
        onError: (error) {
          print('GPS Hatası: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPS hatası: $error')),
          );
        },
      );

      // Süre sayacını başlat
      _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_trackingStartTime != null) {
          setState(() {
            _trackingDuration = DateTime.now().difference(_trackingStartTime!);
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏃‍♂️ GPS takip başladı'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Takip başlatılamadı: $e')),
      );
    }
  }

  void _stopTracking() {
    if (!_isTracking) return;
    
    setState(() => _isTracking = false);
    _positionStream?.cancel();
    _durationTimer?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏹️ GPS takip durduruldu'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _updateLocation(Position position) {
    if (!_isTracking) return;
    
    setState(() {
      // Mesafe hesaplama
      if (_routePoints.isNotEmpty) {
        final lastPoint = _routePoints.last;
        final distance = Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          position.latitude,
          position.longitude,
        );
        _totalDistance += distance;
      }
      
      _routePoints.add(position);
      _currentSpeed = position.speed; // m/s
      
      // Maksimum hız
      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }
      
      // Ortalama hız
      if (_trackingDuration.inSeconds > 0) {
        _averageSpeed = _totalDistance / _trackingDuration.inSeconds;
      }
      
      // Kalori hesaplama (basit formül)
      _calories = _calculateCalories();
    });
  }

  double _calculateCalories() {
    // Kalori = MET * Kilo * Saat
    // Yürüyüş: 3.5 MET, Koşu: 8-12 MET
    final speedKmh = _averageSpeed * 3.6; // m/s to km/h
    double met = 3.5; // Varsayılan yürüyüş
    
    if (speedKmh > 8) {
      met = 8.0; // Koşu
    } else if (speedKmh > 6) {
      met = 5.0; // Hızlı yürüyüş
    }
    
    final hours = _trackingDuration.inSeconds / 3600.0;
    final weight = 70.0; // Varsayılan kilo - user provider'dan alınabilir
    
    return met * weight * hours;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('👣 Adım Detayları'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: 'İstatistik'),
            Tab(icon: Icon(Icons.map), text: 'GPS Takip'),
            Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildGPSTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<AdvancedStepCounterService>(
      builder: (context, stepService, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Bugünkü adımlar
              _buildStatCard(
                title: 'Bugünkü Adımlar',
                value: '${stepService.todaySteps}',
                subtitle: 'Hedef: 10,000',
                icon: Icons.directions_walk,
                color: AppColors.primaryGreen,
                progress: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
              ),
              
              SizedBox(height: 16),
              
              // Tahmini mesafe
              _buildStatCard(
                title: 'Tahmini Mesafe',
                value: '${(stepService.todaySteps * 0.0008).toStringAsFixed(2)} km',
                subtitle: 'Ortalama adım boyu: 80cm',
                icon: Icons.straighten,
                color: Colors.blue,
              ),
              
              SizedBox(height: 16),
              
              // Tahmini kalori
              _buildStatCard(
                title: 'Yakılan Kalori',
                value: '${(stepService.todaySteps * 0.04).toInt()} kal',
                subtitle: 'Adım başına ~0.04 kalori',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              
              SizedBox(height: 16),
              
              // Aktif dakika
              _buildStatCard(
                title: 'Aktif Dakika',
                value: '${(stepService.todaySteps / 100).toInt()} dk',
                subtitle: '100 adım = ~1 dakika',
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGPSTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // GPS Tracking Control
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _isTracking ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _isTracking ? 'GPS Takip Aktif' : 'GPS Takip Durduruldu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isTracking ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTracking ? null : _startTracking,
                          icon: Icon(Icons.play_arrow),
                          label: Text('Başla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTracking ? _stopTracking : null,
                          icon: Icon(Icons.stop),
                          label: Text('Durdur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // GPS Stats
          if (_isTracking || _routePoints.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildGPSStatCard(
                    'Mesafe',
                    '${(_totalDistance / 1000).toStringAsFixed(2)} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildGPSStatCard(
                    'Süre',
                    _formatDuration(_trackingDuration),
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildGPSStatCard(
                    'Hız',
                    '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildGPSStatCard(
                    'Ort. Hız',
                    '${(_averageSpeed * 3.6).toStringAsFixed(1)} km/h',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildGPSStatCard(
                    'Max Hız',
                    '${(_maxSpeed * 3.6).toStringAsFixed(1)} km/h',
                    Icons.flash_on,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildGPSStatCard(
                    'Kalori',
                    '${_calories.toInt()} kal',
                    Icons.local_fire_department,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ],
          
          SizedBox(height: 16),
          
          // Route Info
          if (_routePoints.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🗺️ Rota Bilgileri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('📍 Toplam Nokta: ${_routePoints.length}'),
                    if (_routePoints.length >= 2) ...[
                      Text('🎯 Başlangıç: ${_routePoints.first.latitude.toStringAsFixed(6)}, ${_routePoints.first.longitude.toStringAsFixed(6)}'),
                      Text('🏁 Son Nokta: ${_routePoints.last.latitude.toStringAsFixed(6)}, ${_routePoints.last.longitude.toStringAsFixed(6)}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Geçmiş Aktiviteler',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Yakında eklenecek...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}% tamamlandı',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGPSStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}