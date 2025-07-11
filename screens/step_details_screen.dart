// lib/screens/step_details_screen.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/exercise_provider.dart';
import '../providers/user_provider.dart';
import '../services/native_step_counter_service.dart';
import '../utils/colors.dart';

// Detay ekranındaki büyük, ayrı halkaları çizmek için özel Painter
class SingleActivityRingPainter extends CustomPainter {
  final double progress;
  final Color startColor;
  final Color endColor;
  final double strokeWidth;

  SingleActivityRingPainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    this.strokeWidth = 16.0, // Kalın halka
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arka Plan Halkası
    final backgroundPaint = Paint()
      ..color = startColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

    // İlerleme Halkası (Gradyan ve Parlama ile)
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [startColor, endColor],
          startAngle: -pi / 2,
          endAngle: (2 * pi * progress) - (pi / 2),
          transform: GradientRotation(-pi / 2),
        ).createShader(rect);

      final glowPaint = Paint()
        ..color = endColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, glowPaint);
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SingleActivityRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           startColor != oldDelegate.startColor ||
           endColor != oldDelegate.endColor;
  }
}

class StepDetailsScreen extends StatelessWidget {
  const StepDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stepService = context.watch<NativeStepCounterService>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final user = context.watch<UserProvider>().user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Veri hesaplamaları
    final int steps = stepService.dailySteps;
    final int stepGoal = user?.dailyStepGoal ?? 8000;
    final double stepProgress = (steps / stepGoal).clamp(0.0, 1.0);

    // Yakılan kalori (adımlardan + egzersizden)
    final double burnedFromSteps = (steps * 0.045);
    final double burnedFromExercise = exerciseProvider.getDailyBurnedCalories(DateTime.now());
    final double totalBurnedCalories = burnedFromSteps + burnedFromExercise;
    final double calorieGoal = (user?.dailyCalorieNeeds ?? 2000) * 0.25;
    final double calorieProgress = (totalBurnedCalories / calorieGoal).clamp(0.0, 1.0);

    // Mesafe (KM)
    final double distanceKm = (steps * 0.762) / 1000;
    final double distanceGoal = 5.0; // 5 KM hedef
    final double distanceProgress = (distanceKm / distanceGoal).clamp(0.0, 1.0);
    
    
    final double speed = stepService.isWalking ? 4.5 : 0.0;
    final int activeMinutes = exerciseProvider.getDailyExerciseMinutes(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivite Detayları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Üç Büyük Ayrı Halka
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLargeRing(
                  context,
                  progress: stepProgress,
                  value: steps.toString(),
                  label: 'Adım',
                  startColor: Colors.green,
                  endColor: Colors.green,
                ),
                _buildLargeRing(
                  context,
                  progress: calorieProgress,
                  value: totalBurnedCalories.toInt().toString(),
                  label: 'Kalori',
                  startColor: Colors.red,
                  endColor: Colors.red,
                ),
                _buildLargeRing(
                  context,
                  progress: distanceProgress,
                  value: distanceKm.toStringAsFixed(1),
                  label: 'KM',
                  startColor: Colors.purple,
                  endColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Detaylı İstatistik Kartı
            Card(
              elevation: isDarkMode ? 8 : 6,
              shadowColor: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildDetailRow(context, Icons.map_outlined, 'Mesafe', '${distanceKm.toStringAsFixed(2)} km'),
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.speed, 'Anlık Hız', '${speed.toStringAsFixed(1)} km/s'),
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.timer_outlined, 'Aktif Süre', '$activeMinutes dakika'),
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.local_fire_department, 'Yakılan Kalori', '${totalBurnedCalories.toInt()} kal'),
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.straighten, 'Hedef Mesafe', '${distanceGoal.toInt()} km'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeRing(BuildContext context, {
    required double progress,
    required String value,
    required String label,
    required Color startColor,
    required Color endColor,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 120, // Daha büyük halka
          height: 120,
          child: CustomPaint(
            painter: SingleActivityRingPainter(
              progress: progress,
              startColor: startColor,
              endColor: endColor,
              strokeWidth: 16, // Kalın halka
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}