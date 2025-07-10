// lib/screens/step_details_screen.dart - Hibrit Sistem
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/advanced_step_counter_service.dart';
import '../services/native_step_counter_service.dart';
import '../utils/colors.dart';

class StepDetailsScreen extends StatefulWidget {
  const StepDetailsScreen({super.key});

  @override
  State<StepDetailsScreen> createState() => _StepDetailsScreenState();
}

class _StepDetailsScreenState extends State<StepDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late Animation<double> _ringAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeInOutCubic,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _ringController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Hibrit veri alma sistemi
  StepData _getStepData(BuildContext context) {
    final nativeService = Provider.of<NativeStepCounterService>(context, listen: false);
    final advancedService = Provider.of<AdvancedStepCounterService>(context, listen: false);
    
    // Native sensör varsa ve aktifse ondan al
    if (nativeService.isNativeSensorAvailable && nativeService.isActive) {
      return StepData(
        steps: nativeService.dailySteps,
        isWalking: nativeService.isWalking,
        systemType: 'Native Android Sensör',
        accuracy: 'Yüksek Hassasiyet',
        backgroundColor: Colors.green,
      );
    }
    // Yoksa advanced sistem kullan
    else if (advancedService.isServiceActive) {
      return StepData(
        steps: advancedService.todaySteps,
        isWalking: advancedService.isWalking,
        systemType: 'Accelerometer Tabanlı',
        accuracy: 'Orta Hassasiyet',
        backgroundColor: Colors.orange,
      );
    }
    // Hiçbiri yoksa varsayılan
    else {
      return StepData(
        steps: 0,
        isWalking: false,
        systemType: 'Sensör Bulunamadı',
        accuracy: 'Aktif Değil',
        backgroundColor: Colors.grey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.directions_walk_rounded,
              color: AppColors.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Adım Detayları',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer2<NativeStepCounterService, AdvancedStepCounterService>(
        builder: (context, nativeService, advancedService, child) {
          final stepData = _getStepData(context);
          
          // Hesaplamalar - hangi servisten gelirse gelsin aynı formül
          final distanceKm = (stepData.steps * 0.75) / 1000;
          final avgSpeed = stepData.isWalking ? 4.5 : 0.0;
          final caloriesBurned = (stepData.steps * 0.04).round();
          
          const stepGoal = 8000;
          final progress = (stepData.steps / stepGoal).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Sistem durumu kartı
                _buildSystemStatusCard(stepData, isDark),
                
                const SizedBox(height: 20),
                
                // Ana Adım Sayar Halka
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: stepData.isWalking ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: stepData.backgroundColor.withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Arkaplan halka
                            SizedBox(
                              width: 280,
                              height: 280,
                              child: CustomPaint(
                                painter: StepRingPainter(
                                  progress: 1.0,
                                  color: isDark 
                                      ? Colors.grey[800]! 
                                      : Colors.grey[300]!,
                                  strokeWidth: 12,
                                ),
                              ),
                            ),
                            
                            // İlerleme halka
                            AnimatedBuilder(
                              animation: _ringAnimation,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 280,
                                  height: 280,
                                  child: CustomPaint(
                                    painter: StepRingPainter(
                                      progress: progress * _ringAnimation.value,
                                      color: stepData.backgroundColor,
                                      strokeWidth: 12,
                                      showGlow: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // Merkez içerik
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Adım sayısı
                                Text(
                                  stepData.steps.toString(),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.0,
                                  ),
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Adım yazısı
                                Text(
                                  'ADIM',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: stepData.backgroundColor,
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Hedef bilgisi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stepData.backgroundColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${stepGoal} hedef',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: stepData.backgroundColor,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Yürüme durumu
                                if (stepData.isWalking)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Yürüyor',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // İstatistik kartları
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Üst sıra
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.map_outlined,
                              title: 'Mesafe',
                              value: '${distanceKm.toStringAsFixed(2)} km',
                              color: Colors.blue,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.speed_rounded,
                              title: 'Ortalama Hız',
                              value: '${avgSpeed.toStringAsFixed(1)} km/h',
                              color: Colors.purple,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Alt sıra
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              title: 'Kalori',
                              value: '$caloriesBurned kcal',
                              color: Colors.orange,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.trending_up_rounded,
                              title: 'İlerleme',
                              value: '${(progress * 100).toInt()}%',
                              color: stepData.backgroundColor,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Motivasyon mesajı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        stepData.backgroundColor.withOpacity(0.1),
                        stepData.backgroundColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: stepData.backgroundColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getMotivationIcon(progress),
                        color: stepData.backgroundColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationMessage(progress, stepData.steps, stepGoal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Sistem durumu kartı
  Widget _buildSystemStatusCard(StepData stepData, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stepData.backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stepData.backgroundColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            stepData.systemType.contains('Native') 
                ? Icons.sensors_rounded 
                : Icons.phone_android_rounded,
            color: stepData.backgroundColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepData.systemType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  stepData.accuracy,
                  style: TextStyle(
                    fontSize: 12,
                    color: stepData.backgroundColor,
                  ),
                ),
              ],
            ),
          ),
          if (stepData.systemType.contains('Native'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMotivationIcon(double progress) {
    if (progress >= 1.0) return Icons.emoji_events_rounded;
    if (progress >= 0.75) return Icons.trending_up_rounded;
    if (progress >= 0.5) return Icons.directions_walk_rounded;
    return Icons.rocket_launch_rounded;
  }

  String _getMotivationMessage(double progress, int steps, int goal) {
    if (progress >= 1.0) {
      return 'Tebrikler! Günlük hedefinizi tamamladınız! 🎉';
    } else if (progress >= 0.75) {
      return 'Harika gidiyorsunuz! Hedefe çok yakınsınız! 💪';
    } else if (progress >= 0.5) {
      return 'İyi tempo! Yarı yolu geçtiniz! 🚀';
    } else if (steps > 0) {
      return 'Güzel başlangıç! Devam edin! ⭐';
    } else {
      return 'Hadi başlayalım! İlk adımı atın! 🌟';
    }
  }
}

// Veri modeli
class StepData {
  final int steps;
  final bool isWalking;
  final String systemType;
  final String accuracy;
  final Color backgroundColor;

  StepData({
    required this.steps,
    required this.isWalking,
    required this.systemType,
    required this.accuracy,
    required this.backgroundColor,
  });
}

// Özel halka çizer
class StepRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showGlow;

  StepRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8.0,
    this.showGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Glow efekti
    if (showGlow && progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    // Ana halka
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}