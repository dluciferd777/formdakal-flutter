// lib/widgets/lifestyle_cards.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';

class LifestyleCards extends StatelessWidget {
  const LifestyleCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        final user = userProvider.user;
        final isDarkMode = themeProvider.isDarkMode;
        
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yaşam Tarzı',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  LifestyleCard(
                    title: 'Uyku',
                    icon: Icons.bedtime,
                    color: const Color(0xFF6B73FF),
                    currentValue: 0, // Bu sleep tracking eklenebilir
                    targetValue: 8,
                    unit: 'saat',
                    onTap: () => _showSleepDialog(context),
                  ),
                  LifestyleCard(
                    title: 'Meditasyon',
                    icon: Icons.self_improvement,
                    color: const Color(0xFF9C27B0),
                    currentValue: 0, // Bu meditation tracking eklenebilir
                    targetValue: 20,
                    unit: 'dk',
                    onTap: () => _showMeditationDialog(context),
                  ),
                  LifestyleCard(
                    title: 'Adım Hedefi',
                    icon: Icons.directions_walk,
                    color: AppColors.stepColor,
                    currentValue: 0, // ExerciseProvider'dan günlük adım alınabilir
                    targetValue: user.dailyStepGoal.toDouble(),
                    unit: 'adım',
                    onTap: () => Navigator.pushNamed(context, '/step_details'),
                  ),
                  LifestyleCard(
                    title: 'Kalori Hedefi',
                    icon: Icons.local_fire_department,
                    color: AppColors.calorieColor,
                    currentValue: 0, // FoodProvider'dan günlük kalori alınabilir
                    targetValue: user.dailyCalorieNeeds,
                    unit: 'kal',
                    onTap: () => Navigator.pushNamed(context, '/calorie_tracking'),
                  ),
                  LifestyleCard(
                    title: 'Antrenman',
                    icon: Icons.fitness_center,
                    color: AppColors.primaryGreen,
                    currentValue: 0, // ExerciseProvider'dan günlük dakika alınabilir
                    targetValue: user.dailyMinuteGoal.toDouble(),
                    unit: 'dk',
                    onTap: () => Navigator.pushNamed(context, '/fitness'),
                  ),
                  LifestyleCard(
                    title: 'BMI',
                    icon: Icons.monitor_weight,
                    color: Colors.orange,
                    currentValue: user.bmi,
                    targetValue: 25, // Normal BMI üst sınırı
                    unit: '',
                    showProgress: false,
                    onTap: () => Navigator.pushNamed(context, '/measurements'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showSleepDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bedtime, color: Color(0xFF6B73FF)),
            SizedBox(width: 8),
            Text('Uyku Takibi'),
          ],
        ),
        content: const Text('Uyku takibi özelliği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static void _showMeditationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.self_improvement, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('Meditasyon'),
          ],
        ),
        content: const Text('Meditasyon takibi özelliği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class LifestyleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double currentValue;
  final double targetValue;
  final String unit;
  final VoidCallback onTap;
  final bool showProgress;

  const LifestyleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final progress = showProgress ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (showProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              if (unit.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      _formatValue(currentValue),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (showProgress)
                  Text(
                    'Hedef: ${_formatValue(targetValue)} $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
              ] else ...[
                Text(
                  _formatValue(currentValue),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getBMICategory(currentValue),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
              if (showProgress) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Kilolu';
    return 'Obez';
  }
}