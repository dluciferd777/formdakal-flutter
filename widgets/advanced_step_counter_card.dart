// lib/widgets/advanced_step_counter_card.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:formdakal/widgets/activity_ring_painter.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../services/native_step_counter_service.dart';
import '../utils/colors.dart';

class AdvancedStepCounterCard extends StatelessWidget {
  const AdvancedStepCounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stepService = context.watch<NativeStepCounterService>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final foodProvider = context.watch<FoodProvider>();
    final user = context.watch<UserProvider>().user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ADIM SAYAR VERİLERİ
    final int stepGoal = user?.dailyStepGoal ?? 8000;
    final int steps = stepService.dailySteps;
    final double stepProgress = (steps / stepGoal).clamp(0.0, 1.0);

    // YEMEKTEKİ KALORİ VERİLERİ (Alınan kalori)
    final double dailyCalorieNeeds = user?.dailyCalorieNeeds ?? 2000;
    final double consumedCalories = foodProvider.getDailyCalories(DateTime.now());
    final double foodCalorieProgress = (consumedCalories / dailyCalorieNeeds).clamp(0.0, 1.0);

    // FITNESS KALORİ VERİLERİ (Yakılan kalori)
    final double fitnessCalorieGoal = dailyCalorieNeeds * 0.25; // %25'i fitness hedefi
    final double burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
    final double fitnessCalorieProgress = (burnedCalories / fitnessCalorieGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/step_details'),
      child: Card(
        elevation: isDarkMode ? 8 : 6,
        shadowColor: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding küçültüldü
          child: Row(
            children: [
              // Sol Taraf: Yazılar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      context,
                      icon: Icons.directions_walk,
                      color: AppColors.stepColor, // Yeşil ton - adım için
                      label: 'Adım',
                      value: '$steps',
                      target: '',
                    ),
                    const SizedBox(height: 12), // Boşluk küçültüldü
                    _buildStatRow(
                      context,
                      icon: Icons.restaurant_menu,
                      color: AppColors.calorieColor, // Pembe/kırmızı ton - yemek kalori için
                      label: 'Alınan',
                      value: '${consumedCalories.toInt()}',
                      target: '',
                    ),
                    const SizedBox(height: 12), // Boşluk küçültüldü
                    _buildStatRow(
                      context,
                      icon: Icons.local_fire_department,
                      color: Colors.orange, // Turuncu - fitness kalori için
                      label: 'Yakılan',
                      value: '${burnedCalories.toInt()}',
                      target: '',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // Boşluk küçültüldü
              // Sağ Taraf: Halkalar
              SizedBox(
                width: 80, // Halka boyutu küçültüldü
                height: 80,
                child: CustomPaint(
                  painter: ActivityRingPainter(
                    outerProgress: stepProgress,           // Dış halka - Adım
                    middleProgress: foodCalorieProgress,   // Orta halka - Yemek Kalori (Alınan)
                    innerProgress: fitnessCalorieProgress, // İç halka - Fitness Kalori (Yakılan)
                    outerColor: AppColors.stepColor,       // Yeşil - Adım
                    middleColor: AppColors.calorieColor,   // Pembe/Kırmızı - Yemek Kalori
                    innerColor: Colors.orange,             // Turuncu - Fitness Kalori
                    showGlow: true,
                    customStrokeWidth: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String target,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 20), // İkon boyutu küçültüldü
        const SizedBox(width: 8), // Boşluk küçültüldü
        Text(
          '$label $value', // Label ve value yan yana
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}