// lib/screens/workout_plans_list_screen.dart
import 'package:flutter/material.dart';
import 'package:formdakal/data/workout_plans_data.dart';
import 'package:formdakal/models/workout_plan_model.dart';
import 'package:formdakal/providers/workout_plan_provider.dart';
import 'package:formdakal/screens/edit_workout_plan_screen.dart';
import 'package:formdakal/screens/workout_plan_details_screen.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:provider/provider.dart';
// HATA DÜZELTME: Kullanılmayan import kaldırıldı.
// import '../data/exercises_data.dart';
// import '../models/exercise_model.dart';

class WorkoutPlansListScreen extends StatefulWidget {
  const WorkoutPlansListScreen({super.key});

  @override
  State<WorkoutPlansListScreen> createState() => _WorkoutPlansListScreenState();
}

class _WorkoutPlansListScreenState extends State<WorkoutPlansListScreen> {
  void _showCreatePlanDialog() {
    String? selectedType;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Plan Türü Seç'),
              content: DropdownButton<String>(
                hint: const Text('Plan Türü Seçin'),
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'push', child: Text('İtiş (Push)')),
                  DropdownMenuItem(value: 'pull', child: Text('Çekiş (Pull)')),
                  DropdownMenuItem(value: 'leg', child: Text('Bacak (Leg)')),
                ],
                onChanged: (value) => setDialogState(() => selectedType = value),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: selectedType == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => EditWorkoutPlanScreen(planType: selectedType!),
                          ));
                        },
                  child: const Text("Oluştur"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Planları'),
      ),
      body: SafeArea(
        child: Consumer<WorkoutPlanProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.all(8), // Genel padding daha da küçültüldü
              children: [
                _buildSectionTitle(context, 'Hazır Planlar'),
                const SizedBox(height: 8), // Boşluk daha da küçültüldü
                _buildReadyPlanCard(context, WorkoutPlansData.readyMadePlans['full_body']!),
                const SizedBox(height: 8), // Boşluk daha da küçültüldü
                _buildReadyPlanCard(context, WorkoutPlansData.readyMadePlans['ppl']!),
                const SizedBox(height: 16), // Bölüm başlığı öncesi boşluk daha da küçültüldü
                _buildSectionTitle(context, 'Özel Planlarım'),
                const SizedBox(height: 8), // Boşluk daha da küçültüldü
                _buildCustomPlanCard(context, provider: provider, title: "İtiş Günü (Push)", plan: provider.myPushPlan, planType: 'push'),
                const SizedBox(height: 8), // Boşluk daha da küçültüldü
                _buildCustomPlanCard(context, provider: provider, title: "Çekiş Günü (Pull)", plan: provider.myPullPlan, planType: 'pull'),
                const SizedBox(height: 8), // Boşluk daha da küçültüldü
                _buildCustomPlanCard(context, provider: provider, title: "Bacak Günü (Leg)", plan: provider.myLegPlan, planType: 'leg'),
                const SizedBox(height: 80), // En alttaki boşluk artırıldı
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlanDialog,
        icon: const Icon(Icons.add),
        label: const Text('Özel Plan Oluştur'),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 4.0), // Padding daha da küçültüldü
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)), // Yazı boyutu küçültüldü
    );
  }

  Widget _buildReadyPlanCard(BuildContext context, WorkoutPlanModel plan) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Köşe yuvarlaklığı küçültüldü
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutPlanDetailsScreen(plan: plan)));
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Padding daha da küçültüldü
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryGreen, fontSize: 16)), // Yazı boyutu küçültüldü
              const SizedBox(height: 2), // Boşluk daha da küçültüldü
              Text(plan.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)), // Yazı boyutu küçültüldü
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPlanCard(BuildContext context, {required WorkoutPlanProvider provider, required String title, required WorkoutPlanModel? plan, required String planType}) {
    final exercises = plan?.weeklySchedule[1] ?? [];
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Köşe yuvarlaklığı küçültüldü
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Padding daha da küçültüldü
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)), // Yazı boyutu küçültüldü
                IconButton(
                  icon: const Icon(Icons.edit_note_outlined, color: Colors.blueAccent, size: 20), // İkon boyutu küçültüldü
                  tooltip: "Planı Düzenle",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EditWorkoutPlanScreen(planType: planType, existingPlan: plan),
                    ));
                  },
                ),
              ],
            ),
            const Divider(height: 1, thickness: 0.5), // Divider inceltildi
            if (exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4.0), // Padding daha da küçültüldü
                child: Text("Bu plan boş. Düzenle butonu ile egzersiz ekleyebilirsiniz.", style: TextStyle(color: Colors.grey, fontSize: 11)), // Yazı boyutu küçültüldü
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4.0), // Padding daha da küçültüldü
                child: Text(
                  "${exercises.length} egzersiz içeriyor.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12), // Yazı boyutu küçültüldü
                ),
              ),
            const SizedBox(height: 10), // Buton ile önceki metin arasında boşluk küçültüldü
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: plan == null || exercises.isEmpty ? null : () => provider.addWorkoutDayToLog(context, plan, 1),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 35), // Buton boyutu küçültüldü
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Buton içi padding küçültüldü
                  textStyle: const TextStyle(fontSize: 13), // Buton yazı boyutu küçültüldü
                ),
                child: const Text('Antrenmanı Başlat'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
