// lib/screens/step_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../utils/colors.dart';
import '../widgets/activity_ring_painter.dart';

class StepDetailsScreen extends StatelessWidget {
  const StepDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adım & Aktivite Detayları'),
      ),
      body: SafeArea( // Burası eklendi
        child: Consumer<ExerciseProvider>(
          builder: (context, exerciseProvider, child) {
            final steps = exerciseProvider.dailySteps;
            final activeMinutes = exerciseProvider.dailyActiveMinutes;
            final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
            
            final double distanceKm = (steps * 0.75) / 1000;

            const stepGoal = 6000;
            const minuteGoal = 60;
            const calorieGoal = 300; 

            final stepProgress = (steps / stepGoal).clamp(0.0, 1.0);
            final minuteProgress = (activeMinutes / minuteGoal).clamp(0.0, 1.0);
            final calorieProgress = (burnedCalories / calorieGoal).clamp(0.0, 1.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: ActivityRingPainter(
                        outerProgress: stepProgress,
                        middleProgress: minuteProgress,
                        innerProgress: calorieProgress,
                        outerColor: AppColors.stepColor,
                        middleColor: AppColors.timeColor,
                        innerColor: AppColors.calorieColor,
                        showGlow: true,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_walk, color: AppColors.stepColor, size: 40),
                            const SizedBox(height: 8),
                            Text(steps.toString(), style: Theme.of(context).textTheme.displaySmall),
                            Text("Adım", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem(context, 'Etkin Süre', activeMinutes.toString(), AppColors.timeColor, '${minuteGoal}dk hedef'),
                      _buildDetailItem(context, 'Aktivite Kalorisi', burnedCalories.toInt().toString(), AppColors.calorieColor, '${calorieGoal}kal hedef'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Divider(),
                  const SizedBox(height: 16),

                  _buildSummaryRow(context, 'Kat Edilen Mesafe', '${distanceKm.toStringAsFixed(2)} km', Icons.map_outlined),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, Color color, String goalText) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          goalText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            const SizedBox(width: 16),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
