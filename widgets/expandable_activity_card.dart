// lib/widgets/expandable_activity_card.dart - DÜZELTİLMİŞ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart'; // Kullanılmadığı için kaldırıldı
import '../models/exercise_model.dart';
import '../providers/achievement_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../utils/colors.dart';
// import '../services/calorie_service.dart'; // Kullanılmadığı için kaldırıldı

enum ActivityCardType {
  fitness,
  food,
  calorieTracking,
  water,
  achievements
}

class ExpandableActivityCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final ActivityCardType type;

  const ExpandableActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  State<ExpandableActivityCard> createState() => _ExpandableActivityCardState();
}

class _ExpandableActivityCardState extends State<ExpandableActivityCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  String _buildExerciseDetails(CompletedExercise exercise) {
    if (exercise.category == 'cardio') {
      String details = '${exercise.durationMinutes} dk';
      if (exercise.distanceKm != null && exercise.distanceKm! > 0) {
        details += ' | ${exercise.distanceKm!.toStringAsFixed(1)} km';
      }
      if (exercise.inclinePercent != null && exercise.inclinePercent! > 0) {
        details += ' | %${exercise.inclinePercent!.toInt()}';
      }
      return details;
    } else {
      String details = '${exercise.sets}×${exercise.reps}';
      if (exercise.weight != null && exercise.weight! > 0) {
        details += ' @ ${exercise.weight!.toInt()}kg';
      }
      return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: widget.color)),
                      Text(widget.unit, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.expand_more, color: widget.color),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    switch (widget.type) {
      case ActivityCardType.fitness: return _buildFitnessContent();
      case ActivityCardType.food: return _buildFoodContent();
      case ActivityCardType.calorieTracking: return _buildCalorieTrackingContent();
      case ActivityCardType.water: return _buildWaterContent();
      case ActivityCardType.achievements: return _buildAchievementsContent();
    }
  }
  
  Widget _buildFitnessContent() {
    return Consumer<ExerciseProvider>(
      builder: (context, exerciseProvider, child) {
        final todayExercises = exerciseProvider.completedExercises.where((e) => _isToday(e.completedAt)).toList();
        if (todayExercises.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('Bugün henüz egzersiz yapmadınız.', style: TextStyle(color: Colors.grey)),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              ...todayExercises.map((exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${exercise.exerciseName} (${_buildExerciseDetails(exercise)})', style: Theme.of(context).textTheme.bodyMedium)),
                    Text('${exercise.burnedCalories.toInt()} kal', style: TextStyle(color: widget.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodContent() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final todayConsumedFoods = foodProvider.consumedFoods.where((food) => _isToday(food.consumedAt)).toList();
        if (todayConsumedFoods.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('Bugün henüz yemek eklemediniz.', style: TextStyle(color: Colors.grey)),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              ...todayConsumedFoods.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${food.foodName} (${food.grams.toInt()}g)', style: Theme.of(context).textTheme.bodyMedium)),
                    Text('${food.totalCalories.toInt()} kal', style: TextStyle(color: widget.color, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalorieTrackingContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Consumer3<FoodProvider, ExerciseProvider, UserProvider>(
      builder: (context, foodProvider, exerciseProvider, userProvider, child) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        final consumedCalories = foodProvider.getDailyCalories(DateTime.now());
        final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
        final targetCalories = user.dailyCalorieNeeds;
        final remainingCalories = targetCalories - consumedCalories + burnedCalories;
        
        final bmr = user.bmr.toInt();
        final tdee = user.dailyCalorieNeeds.toInt();

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: AppColors.calorieColor.withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('Alınan', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
                            const SizedBox(height: 4),
                            Text(consumedCalories.toInt().toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.calorieColor, fontWeight: FontWeight.bold, fontSize: 20)),
                            Text('kal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.calorieColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text('Yakılan', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54)),
                            const SizedBox(height: 4),
                            Text(burnedCalories.toInt().toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 20)),
                            Text('kal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryGreen)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Günlük Kalori Özeti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCalorieStatItem('Hedef', targetCalories.toInt(), AppColors.primaryGreen),
                  _buildCalorieStatItem('Alınan', consumedCalories.toInt(), AppColors.calorieColor),
                  _buildCalorieStatItem('Yakılan', burnedCalories.toInt(), AppColors.primaryGreen),
                  _buildCalorieStatItem('Kalan', remainingCalories.toInt(), Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 12),
              Text('BMR: $bmr kal | TDEE: $tdee kal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDarkMode ? Colors.white70 : Colors.black54)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          // Wrap kullanarak overflow'u önledik
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildWaterButton(context, 250),
              _buildWaterButton(context, 500),
              _buildWaterButton(context, 750),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsContent() {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        final unlockedAchievements = achievementProvider.achievements.where((a) => a.isUnlocked).toList();
        if (unlockedAchievements.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('Henüz hiç başarım kazanmadın. Devam et!', style: TextStyle(color: Colors.grey)),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              ...unlockedAchievements.take(3).map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(achievement.icon, color: achievement.color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(achievement.name, style: Theme.of(context).textTheme.bodyLarge)),
                    const Text('Kazanıldı!', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tümünü Gör'),
                  onPressed: () => Navigator.pushNamed(context, '/achievements'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterButton(BuildContext context, int amountMl) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add, size: 18),
      label: Text('$amountMl ml'),
      onPressed: () {
        Provider.of<UserProvider>(context, listen: false).addWater(amountMl / 1000.0);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$amountMl ml su eklendi.'), backgroundColor: AppColors.success));
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: widget.color.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCalorieStatItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Text('$value kal', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}