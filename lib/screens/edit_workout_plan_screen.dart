// lib/screens/edit_workout_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../data/exercises_data.dart';
import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../providers/workout_plan_provider.dart';
import '../utils/colors.dart';
import 'select_exercise_screen.dart';

class EditWorkoutPlanScreen extends StatefulWidget {
  final String planType;
  final WorkoutPlanModel? existingPlan;

  const EditWorkoutPlanScreen({
    super.key,
    required this.planType,
    this.existingPlan,
  });

  @override
  State<EditWorkoutPlanScreen> createState() => _EditWorkoutPlanScreenState();
}

class _EditWorkoutPlanScreenState extends State<EditWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _planNameController;
  late List<ExerciseInPlan> _exercises;
  late String _planId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingPlan != null;

    if (_isEditing) {
      final plan = widget.existingPlan!;
      _planId = plan.id;
      _planNameController = TextEditingController(text: plan.name);
      _exercises = List.from(plan.weeklySchedule[1] ?? []);
    } else {
      _planId = const Uuid().v4();
      _planNameController = TextEditingController(text: _getDefaultPlanName());
      _exercises = [];
    }
  }
  
  String _getDefaultPlanName() {
    switch (widget.planType) {
      case 'push': return 'Özel İtiş Planım';
      case 'pull': return 'Özel Çekiş Planım';
      case 'leg': return 'Özel Bacak Planım';
      default: return 'Özel Planım';
    }
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final selectedExerciseId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
    );

    if (selectedExerciseId != null && mounted) {
      final exercise = ExercisesData.getFullExerciseListAsMap()
          .values
          .expand((e) => e)
          .firstWhere((e) => e.id == selectedExerciseId);
          
      final exerciseDetails = await _showAddExerciseDetailsDialog(exercise);
      if (exerciseDetails != null) {
        setState(() {
          _exercises.add(exerciseDetails);
        });
      }
    }
  }

  Future<ExerciseInPlan?> _showAddExerciseDetailsDialog(ExerciseModel exercise) async {
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final durationController = TextEditingController();

    bool isCardio = exercise.category == 'cardio';

    return await showDialog<ExerciseInPlan>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(exercise.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCardio) ...[
                  TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Set', hintText: 'örn: 3')),
                  const SizedBox(height: 8),
                  TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Tekrar', hintText: 'örn: 12')),
                  const SizedBox(height: 8),
                  TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ağırlık (kg, opsiyonel)')),
                ] else ...[
                  TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Süre (dk)')),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () {
                final newExerciseInPlan = ExerciseInPlan(
                  exerciseId: exercise.id,
                  sets: setsController.text.isNotEmpty ? setsController.text : null,
                  reps: repsController.text.isNotEmpty ? repsController.text : null,
                  weight: weightController.text.isNotEmpty ? weightController.text : null,
                  duration: durationController.text.isNotEmpty ? durationController.text : null,
                );
                Navigator.pop(context, newExerciseInPlan);
              },
              child: const Text('Plana Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _savePlan() {
    if (_formKey.currentState!.validate()) {
      final schedule = { 1: _exercises };

      final newPlan = WorkoutPlanModel(
        id: _planId,
        name: _planNameController.text,
        description: '${widget.planType.toUpperCase()} günü için özel plan.',
        durationWeeks: 1,
        weeklySchedule: schedule,
      );

      Provider.of<WorkoutPlanProvider>(context, listen: false).saveCustomPlan(newPlan, widget.planType);
      Navigator.pop(context);
    }
  }
  
  String _buildExerciseDetails(ExerciseInPlan ex) {
    if (ex.duration != null && ex.duration!.isNotEmpty) {
      return '${ex.duration} dk';
    } else {
      String details = '${ex.sets ?? "0"} × ${ex.reps ?? "0"}';
      if (ex.weight != null && ex.weight!.isNotEmpty) details += ' @ ${ex.weight} kg';
      return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Planı Düzenle' : 'Yeni Plan Oluştur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlan,
            tooltip: 'Planı Kaydet',
          )
        ],
      ),
      body: SafeArea( // Burası eklendi
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _planNameController,
                  decoration: const InputDecoration(labelText: 'Plan Adı', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir plan adı girin.' : null,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _exercises.isEmpty
                    ? const Center(child: Text('Bu plana egzersiz eklemek için aşağıdaki butonu kullanın.'))
                    : ReorderableListView(
                        padding: const EdgeInsets.all(8),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        children: _exercises.map((ex) {
                          final details = ExercisesData.getFullExerciseListAsMap().values.expand((e) => e).firstWhere((e) => e.id == ex.exerciseId);
                          return Card(
                            key: ValueKey(ex),
                            child: ListTile(
                              leading: const Icon(Icons.drag_handle),
                              title: Text(details.name),
                              subtitle: Text(_buildExerciseDetails(ex)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => setState(() => _exercises.remove(ex)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: const Text('Egzersiz Ekle'),
      ),
    );
  }
}
