// lib/widgets/step_counter_card.dart - YENİ GÖLGE SİSTEMİ İLE GÜNCELLENDİ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../utils/colors.dart';
import '../utils/theme.dart'; // YENİ EKLEME
import 'activity_ring_painter.dart';

class StepCounterCard extends StatelessWidget {
  const StepCounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // ESKİ: Card widget
      // YENİ: Container + custom decoration
      decoration: AppTheme.cardDecoration(context),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/step_details');
        },
        borderRadius: BorderRadius.circular(16), // Decoration ile uyumlu
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Consumer<ExerciseProvider>(
            builder: (context, exerciseProvider, child) {
              final steps = exerciseProvider.dailySteps;
              final activeMinutes = exerciseProvider.dailyActiveMinutes;
              final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());

              const stepGoal = 6000;
              const minuteGoal = 60;
              const calorieGoal = 500;

              final stepProgress = (steps / stepGoal).clamp(0.0, 1.0);
              final minuteProgress = (activeMinutes / minuteGoal).clamp(0.0, 1.0);
              final calorieProgress = (burnedCalories / calorieGoal).clamp(0.0, 1.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricRow(context, Icons.directions_walk, '$steps', 'adım', AppColors.stepColor),
                        const SizedBox(height: 8),
                        _buildMetricRow(context, Icons.timer_outlined, '$activeMinutes', 'dak', AppColors.timeColor),
                        const SizedBox(height: 8),
                        _buildMetricRow(context, Icons.local_fire_department_outlined, '${burnedCalories.toInt()}', 'kal', AppColors.calorieColor),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: ActivityRingPainter(
                        outerProgress: stepProgress,
                        middleProgress: minuteProgress,
                        innerProgress: calorieProgress,
                        outerColor: AppColors.stepColor,
                        middleColor: AppColors.timeColor,
                        innerColor: AppColors.calorieColor,
                        showGlow: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, IconData icon, String value, String unit, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color.withOpacity(0.8),
              ),
        ),
      ],
    );
  }
}