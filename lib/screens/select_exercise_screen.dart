// lib/screens/select_exercise_screen.dart
import 'package:flutter/material.dart';
import '../data/exercises_data.dart'; // YENİ: Merkezi veri dosyası import edildi
import '../utils/colors.dart';

class SelectExerciseScreen extends StatelessWidget {
  const SelectExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DÜZELTME: Veriler artık merkezi dosyadan okunuyor
    final categories = ExercisesData.getExerciseCategories();
    final exercises = ExercisesData.getFullExerciseListAsMap();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersiz Seç'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea( // Burası eklendi
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final categoryKey = categories.keys.elementAt(index);
            final categoryName = categories[categoryKey]!;
            final exercisesInCategory = exercises[categoryKey] ?? [];

            return ExpansionTile(
              title: Text(
                categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              children: exercisesInCategory.map((exercise) {
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(exercise.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context, exercise.id);
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
