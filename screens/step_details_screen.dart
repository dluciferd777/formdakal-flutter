// lib/screens/step_details_screen.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle için eklendi
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/user_provider.dart';
import '../services/native_step_counter_service.dart';
import '../utils/colors.dart';
import '../widgets/activity_ring_painter.dart'; // ActivityRingPainter için eklendi

// Detay ekranındaki büyük, ayrı halkaları çizmek için özel Painter (Artık kullanılmayacak ama kalsın)
// class SingleActivityRingPainter extends CustomPainter { // Bu sınıf artık kullanılmıyor, kaldırılabilir veya yorum satırı yapılabilir.
//   final double progress;
//   final Color startColor;
//   final Color endColor;
//   final double strokeWidth;

//   SingleActivityRingPainter({
//     required this.progress,
//     required this.startColor,
//     required this.endColor,
//     this.strokeWidth = 16.0, // Kalın halka
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.width - strokeWidth) / 2;
//     final rect = Rect.fromCircle(center: center, radius: radius);

//     // Arka Plan Halkası
//     final backgroundPaint = Paint()
//       ..color = startColor.withOpacity(0.15)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;
//     canvas.drawArc(rect, 0, 2 * pi, false, backgroundPaint);

//     // İlerleme Halkası (Gradyan ve Parlama ile)
//     if (progress > 0) {
//       final progressPaint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth
//         ..strokeCap = StrokeCap.round
//         ..shader = SweepGradient(
//           colors: [startColor, endColor],
//           startAngle: -pi / 2,
//           endAngle: (2 * pi * progress) - (pi / 2),
//           transform: GradientRotation(-pi / 2),
//         ).createShader(rect);

//       final glowPaint = Paint()
//         ..color = endColor.withOpacity(0.5)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

//       canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, glowPaint);
//       canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant SingleActivityRingPainter oldDelegate) {
//     return progress != oldDelegate.progress ||
//            startColor != oldDelegate.startColor ||
//            endColor != oldDelegate.endColor;
//   }
// }

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
    final double calorieGoal = (user?.dailyCalorieNeeds ?? 2000) * 0.25; // %25'i fitness hedefi
    final double calorieProgress = (totalBurnedCalories / calorieGoal).clamp(0.0, 1.0);

    // Mesafe (KM)
    final double distanceKm = (steps * 0.762) / 1000;
    final double distanceGoal = 5.0; // 5 KM hedef
    final double distanceProgress = (distanceKm / distanceGoal).clamp(0.0, 1.0);
    
    // final double speed = stepService.isWalking ? 4.5 : 0.0; // isWalking kaldırıldığı için bu satır da kaldırıldı
    final int activeMinutes = exerciseProvider.getDailyExerciseMinutes(DateTime.now());

    // Metin renkleri için varsayılan değerler
    final Color defaultTextColor = isDarkMode ? Colors.white : Colors.black;


    return Scaffold(
      // AppBar'ın arka plan rengini ve durum çubuğu ikonlarını temaya göre ayarla
      // Artık Theme.of(context).appBarTheme'den alacak
      appBar: AppBar(
        title: const Text('Aktivite Detayları'),
        // backgroundColor ve systemOverlayStyle kaldırıldı, tema tarafından yönetilecek
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Büyük Üçlü Halka
            SizedBox(
              width: 250, // Halka boyutunu büyüttük
              height: 250,
              child: CustomPaint(
                painter: ActivityRingPainter(
                  outerProgress: stepProgress,           // Dış halka - Adım
                  middleProgress: calorieProgress,       // Orta halka - Kalori
                  innerProgress: distanceProgress,       // İç halka - KM
                  outerColor: AppColors.stepColor,       // Adım rengi
                  middleColor: AppColors.calorieColor,   // Kalori rengi
                  innerColor: Colors.purple,             // KM rengi
                  showGlow: true,
                  customStrokeWidth: 10, // Halka kalınlığını incelttik
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        steps.toString(),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.stepColor, // Adım rengiyle uyumlu
                          fontSize: 48, // Adım sayısını daha büyük yaptık
                        ),
                      ),
                      Text(
                        'Adım',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                    _buildDetailRow(context, Icons.directions_walk, 'Adım', '${steps} adım', AppColors.stepColor), // Renk eklendi
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.map_outlined, 'Mesafe', '${distanceKm.toStringAsFixed(2)} km', Colors.purple), // Renk eklendi
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.local_fire_department, 'Yakılan Kalori', '${totalBurnedCalories.toInt()} kal', AppColors.calorieColor), // Renk eklendi
                    const Divider(height: 24),
                    // _buildDetailRow(context, Icons.speed, 'Anlık Hız', '${speed.toStringAsFixed(1)} km/s', defaultTextColor), // Anlık Hız satırı kaldırıldı
                    // const Divider(height: 24), // Anlık Hız kaldırıldığı için divider da kaldırıldı
                    _buildDetailRow(context, Icons.timer_outlined, 'Aktif Süre', '$activeMinutes dakika', defaultTextColor), // Temaya göre renk
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.straighten, 'Hedef Mesafe', '${distanceGoal.toInt()} km', defaultTextColor), // Temaya göre renk
                    const Divider(height: 24),
                    _buildDetailRow(context, Icons.run_circle_outlined, 'Hedef Adım', '${stepGoal.toInt()} adım', defaultTextColor), // Temaya göre renk
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24), // İkon rengi dinamikleştirildi
        const SizedBox(width: 16),
        Text(label, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black)), // Metin rengi temaya göre, null kontrolü eklendi
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black)), // Metin rengi temaya göre, null kontrolü eklendi
      ],
    );
  }
}
