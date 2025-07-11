// lib/screens/fitness_screen.dart - APPBAR VE CARD GÖLGE DÜZELTİLDİ
import 'package:flutter/material.dart';
import 'package:formdakal/data/exercises_data.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/theme_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/exercise_model.dart';
import '../services/calorie_service.dart';
import '../utils/colors.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> with AutomaticKeepAliveClientMixin {
  String? _expandedCategory;

  final Map<String, String> _categories = ExercisesData.getExerciseCategories();
  final Map<String, List<ExerciseModel>> _exercises = ExercisesData.getFullExerciseListAsMap();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // DÜZELTİLMİŞ APPBAR - Tema uyumlu
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: isDarkMode ? 0 : 2,
        centerTitle: true,
        title: const Text(
          'Fitness & Egzersiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Egzersiz Kategorileri Bölümü
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final categoryKey = _categories.keys.elementAt(index);
                    final categoryName = _categories[categoryKey]!;
                    final isExpanded = _expandedCategory == categoryKey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      elevation: isDarkMode ? 6 : 4,
                      shadowColor: isDarkMode
                          ? Colors.black.withOpacity(0.7)
                          : Colors.grey.withOpacity(0.4),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        leading: Icon(_getCategoryIcon(categoryKey), color: AppColors.primaryGreen, size: 20),
                        title: Text(categoryName, style: theme.textTheme.titleLarge?.copyWith(fontSize: 15)),
                        trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanding) => setState(() =>
                            _expandedCategory = expanding ? categoryKey : null),
                        children: (_exercises[categoryKey] ?? []).map((exercise) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            title: Text(exercise.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
                            subtitle: Text(exercise.description, 
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _showExerciseDialog(exercise),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(50, 25),
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(fontSize: 10),
                              ),
                              child: const Text('Ekle'),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
            
            // "Bugün Tamamlananlar" Başlığı
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Bugün Tamamlananlar", style: theme.textTheme.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bugün Tamamlanan Egzersizler Listesi
            Consumer<ExerciseProvider>(
              builder: (context, exerciseProvider, child) {
                final todayExercises = exerciseProvider.completedExercises
                    .where((e) => _isToday(e.completedAt))
                    .toList();
                  
                if (todayExercises.isEmpty) {
                  return SliverToBoxAdapter(
                    child: const Center(
                        child: Text('Henüz egzersiz eklenmedi.',
                            style: TextStyle(color: Colors.grey, fontSize: 16))),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = todayExercises[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: isDarkMode ? 6 : 4,
                          shadowColor: isDarkMode
                              ? Colors.black.withOpacity(0.7)
                              : Colors.grey.withOpacity(0.4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: Text(exercise.exerciseName, 
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
                            subtitle: Text(_buildExerciseSubtitle(exercise), 
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: AppColors.error),
                              onPressed: () => _deleteExercise(exercise.id),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: todayExercises.length,
                  ),
                );
              },
            ),
            
            // Alt boşluk
            SliverToBoxAdapter(
              child: const SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  String _buildExerciseSubtitle(CompletedExercise exercise) {
    if (exercise.category == 'cardio') {
      String details = '${exercise.durationMinutes} dk';
      if (exercise.distanceKm != null && exercise.distanceKm! > 0) {
        details += ' | ${exercise.distanceKm!.toStringAsFixed(1)} km';
      }
      if (exercise.inclinePercent != null && exercise.inclinePercent! > 0) {
        details += ' | %${exercise.inclinePercent!.toInt()} eğim';
      }
      details += ' | ${exercise.burnedCalories.toInt()} kal';
      return details;
    } else {
      String details = '${exercise.sets}×${exercise.reps}';
      if (exercise.weight != null && exercise.weight! > 0) {
        details += ' @ ${exercise.weight!.toInt()}kg';
      }
      details += ' | ${exercise.burnedCalories.toInt()} kal';
      return details;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'chest': return Icons.fitness_center;
      case 'back': return Icons.sports_gymnastics;
      case 'shoulder': return Icons.sports_handball;
      case 'arm': return Icons.sports_martial_arts;
      case 'leg': return Icons.directions_run;
      case 'cardio': return Icons.favorite;
      case 'core': return Icons.accessibility_new;
      case 'full_body': return Icons.self_improvement;
      default: return Icons.fitness_center;
    }
  }

  Future<void> _showExerciseDialog(ExerciseModel exercise) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lütfen önce profil bilgilerinizi girin.')));
      }
      return;
    }

    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final durationController = TextEditingController();
    final speedController = TextEditingController(); 
    final inclineController = TextEditingController();

    bool isCardio = exercise.category == 'cardio';
    bool isTreadmill = exercise.id.contains('treadmill');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(exercise.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCardio) ...[
                  TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Set Sayısı', hintText: 'örn: 3')),
                  TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tekrar Sayısı', hintText: 'örn: 12')),
                  TextField(controller: weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ağırlık (kg, opsiyonel)')),
                ] else ...[
                  TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Süre (Dakika)', hintText: 'örn: 25')),
                  if (isTreadmill) ...[
                    const SizedBox(height: 10),
                    TextField(controller: speedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Hız (km/saat)', hintText: 'örn: 4.6')),
                    const SizedBox(height: 10),
                    TextField(controller: inclineController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Eğim (%)', hintText: 'örn: 12')),
                  ]
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                _addExerciseToLog(
                  exercise,
                  user.weight,
                  sets: setsController.text,
                  reps: repsController.text,
                  weight: weightController.text,
                  duration: durationController.text,
                  speed: speedController.text,
                  incline: inclineController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _addExerciseToLog(ExerciseModel exercise, double userWeight,
      {String? sets, String? reps, String? weight, String? duration, String? speed, String? incline}) {
    CompletedExercise? completedExercise;
    double burnedCalories = 0;

    final cleanWeight = (weight ?? '').replaceAll(',', '.');
    final cleanSpeed = (speed ?? '').replaceAll(',', '.');
    final cleanIncline = (incline ?? '').replaceAll(',', '.');

    if (exercise.category == 'cardio') {
      final int dur = int.tryParse(duration ?? '') ?? 0;
      if (dur <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli süre girin.'), backgroundColor: AppColors.error));
        return;
      }
      final double spd = double.tryParse(cleanSpeed) ?? 0.0;
      final double inc = double.tryParse(cleanIncline) ?? 0.0;

      burnedCalories = CalorieService.calculateCardioCalories(
          exerciseType: exercise.id, userWeight: userWeight, durationMinutes: dur,
          speed: spd > 0 ? spd : null,
          incline: inc > 0 ? inc : null);

      completedExercise = CompletedExercise(
        exerciseId: exercise.id, exerciseName: exercise.name, category: exercise.category,
        sets: 0, reps: 0, durationMinutes: dur, burnedCalories: burnedCalories, completedAt: DateTime.now(),
        distanceKm: spd > 0 && dur > 0 ? (spd * dur / 60.0) : null,
        speedKmh: spd > 0 ? spd : null,
        inclinePercent: inc > 0 ? inc : null);
    } else {
      final int s = int.tryParse(sets ?? '') ?? 0;
      final int r = int.tryParse(reps ?? '') ?? 0;
      if (s <= 0 || r <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli set ve tekrar girin.'), backgroundColor: AppColors.error));
        return;
      }
      final double w = double.tryParse(cleanWeight) ?? 0.0;

      burnedCalories = CalorieService.calculateEnhancedExerciseCalories(
          metValue: exercise.metValue, userWeight: userWeight, sets: s, reps: r, weightKg: w);
      
      completedExercise = CompletedExercise(
        exerciseId: exercise.id, exerciseName: exercise.name, category: exercise.category,
        sets: s, reps: r, weight: w > 0 ? w : null,
        durationMinutes: CalorieService.estimateExerciseDuration(s, r),
        burnedCalories: burnedCalories, completedAt: DateTime.now());
    }

    Provider.of<ExerciseProvider>(context, listen: false).addCompletedExercise(completedExercise);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${exercise.name} eklendi! Yakılan kalori: ${burnedCalories.toInt()}'),
          backgroundColor: AppColors.success));
    }
  }

  void _deleteExercise(String id) {
    Provider.of<ExerciseProvider>(context, listen: false).removeCompletedExerciseById(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egzersiz silindi.'), backgroundColor: AppColors.error),
      );
    }
  }
}