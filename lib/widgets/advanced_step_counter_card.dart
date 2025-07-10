// lib/widgets/advanced_step_counter_card.dart - SAMSUNG HEALTH TARZINDA (KENDİ RENKLERİMİZ)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/advanced_step_counter_service.dart';
import '../providers/user_provider.dart';
import '../providers/exercise_provider.dart';
import '../utils/colors.dart';

class AdvancedStepCounterCard extends StatelessWidget {
  const AdvancedStepCounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, AdvancedStepCounterService, ExerciseProvider>(
      builder: (context, userProvider, stepService, exerciseProvider, child) {
        final user = userProvider.user;
        final todaySteps = stepService.todaySteps;
        final stepGoal = user?.dailyStepGoal ?? 6000;
        final activeMinutes = exerciseProvider.getDailyExerciseMinutes(DateTime.now());
        final burnedCalories = stepService.getCaloriesFromSteps();
        
        // Progress yüzdeleri
        final stepProgress = (todaySteps / stepGoal).clamp(0.0, 1.0);
        final minuteProgress = (activeMinutes / 90).clamp(0.0, 1.0); // 90 dk hedef
        final calorieProgress = (burnedCalories / 500).clamp(0.0, 1.0); // 500 kal hedef

        return Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2E)
                      : Colors.white,
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : Colors.grey[50]!,
                ],
              ),
            ),
            child: Row(
              children: [
                // Sol taraf - İstatistikler
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Adım
                      _buildStatRow(
                        context,
                        Icons.directions_walk,
                        Colors.purple, // Samsung'dan farklı renk
                        '$todaySteps',
                        'adım',
                        '/$stepGoal',
                      ),
                      // Dakika
                      _buildStatRow(
                        context,
                        Icons.timer,
                        Colors.blue, // Turuncu yerine mavi
                        '$activeMinutes',
                        'dak',
                        '/90 dak',
                      ),
                      // Kalori
                      _buildStatRow(
                        context,
                        Icons.local_fire_department,
                        Colors.red[400]!, // Samsung'dan farklı renk
                        '$burnedCalories',
                        'kal',
                        '/500 kal',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Sağ taraf - Çok renkli halkalar
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dış halka - Adım (Mor)
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: stepProgress,
                              strokeWidth: 6,
                              backgroundColor: Colors.purple.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Orta halka - Dakika (Mavi)
                          SizedBox(
                            width: 65,
                            height: 65,
                            child: CircularProgressIndicator(
                              value: minuteProgress,
                              strokeWidth: 5,
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // İç halka - Kalori (Kırmızı)
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: calorieProgress,
                              strokeWidth: 4,
                              backgroundColor: Colors.red[400]!.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Ortadaki servis durumu göstergesi
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: stepService.isServiceActive
                                  ? AppColors.primaryGreen
                                  : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String unit,
    String goal,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // İkon
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        
        // Değer ve birim
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                goal,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Backward compatibility
class StepCounterCard extends AdvancedStepCounterCard {
  const StepCounterCard({super.key});
}