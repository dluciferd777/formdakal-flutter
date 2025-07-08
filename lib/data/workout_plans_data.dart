// lib/data/workout_plans_data.dart
import '../models/workout_plan_model.dart';

class WorkoutPlansData {
  static final Map<String, WorkoutPlanModel> readyMadePlans = {
    'full_body': WorkoutPlanModel(
      id: 'beginner_full_body',
      name: 'Yeni Başlayanlar İçin Tüm Vücut',
      description: 'Haftada 3 gün uygulanacak ve tüm ana kas gruplarını çalıştıracak temel bir programdır.',
      durationWeeks: 4,
      weeklySchedule: {
        1: [ // A Günü
          ExerciseInPlan(exerciseId: 'barbell_squat_back', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'barbell_bench_press', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'barbell_row', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'seated_dumbbell_shoulder_press', sets: '2', reps: '10-15'),
          ExerciseInPlan(exerciseId: 'plank', duration: '60'), // Süre saniye olarak
        ],
        3: [ // B Günü
          ExerciseInPlan(exerciseId: 'deadlift', sets: '3', reps: '6-8'),
          ExerciseInPlan(exerciseId: 'pull_up', sets: '3', reps: 'Maksimum'),
          ExerciseInPlan(exerciseId: 'dumbbell_lunge', sets: '3', reps: '10-12'),
          ExerciseInPlan(exerciseId: 'dumbbell_fly', sets: '2', reps: '12-15'),
          ExerciseInPlan(exerciseId: 'leg_raise', sets: '3', reps: '15-20'),
        ],
        5: [ // C Günü (A Gününe benzer ama farklı egzersizlerle)
          ExerciseInPlan(exerciseId: 'leg_press', sets: '3', reps: '10-15'),
          ExerciseInPlan(exerciseId: 'incline_dumbbell_press', sets: '3', reps: '10-12'),
          ExerciseInPlan(exerciseId: 'seated_cable_row', sets: '3', reps: '10-12'),
          ExerciseInPlan(exerciseId: 'dumbbell_lateral_raise', sets: '3', reps: '12-15'),
          ExerciseInPlan(exerciseId: 'treadmill_walk', duration: '15'), // Süre dakika olarak
        ],
      },
    ),
    // DÜZELTME: PPL planının içi dolduruldu.
    'ppl': WorkoutPlanModel(
      id: 'push_pull_legs',
      name: 'İtiş / Çekiş / Bacak (PPL)',
      description: 'Orta ve ileri seviye için popüler bir antrenman ayrımıdır. Haftada 3 veya 6 gün uygulanabilir.',
      durationWeeks: 8,
      weeklySchedule: {
        1: [ // İtiş (Push) Günü
          ExerciseInPlan(exerciseId: 'barbell_bench_press', sets: '4', reps: '6-10'),
          ExerciseInPlan(exerciseId: 'incline_dumbbell_press', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'seated_dumbbell_shoulder_press', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'dumbbell_lateral_raise', sets: '3', reps: '12-15'),
          ExerciseInPlan(exerciseId: 'tricep_pushdown_rope', sets: '3', reps: '10-15'),
          ExerciseInPlan(exerciseId: 'skullcrusher', sets: '3', reps: '10-12'),
        ],
        2: [ // Çekiş (Pull) Günü
          ExerciseInPlan(exerciseId: 'deadlift', sets: '3', reps: '5-8'),
          ExerciseInPlan(exerciseId: 'pull_up', sets: '4', reps: 'Maksimum'),
          ExerciseInPlan(exerciseId: 'barbell_row', sets: '3', reps: '8-10'),
          ExerciseInPlan(exerciseId: 'face_pull', sets: '3', reps: '15-20'),
          ExerciseInPlan(exerciseId: 'barbell_curl', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'hammer_curl', sets: '3', reps: '10-15'),
        ],
        3: [ // Bacak (Leg) Günü
          ExerciseInPlan(exerciseId: 'barbell_squat_back', sets: '4', reps: '6-10'),
          ExerciseInPlan(exerciseId: 'romanian_deadlift', sets: '3', reps: '8-12'),
          ExerciseInPlan(exerciseId: 'leg_press', sets: '3', reps: '10-15'),
          ExerciseInPlan(exerciseId: 'leg_extension', sets: '3', reps: '12-15'),
          ExerciseInPlan(exerciseId: 'leg_curl_lying', sets: '3', reps: '12-15'),
          ExerciseInPlan(exerciseId: 'calf_raise_standing', sets: '4', reps: '15-20'),
        ],
        // Kullanıcı isterse haftada 6 gün için bu günler tekrar edilebilir.
        // Şimdilik 3 gün olarak bırakıldı.
      },
    ),
  };
}
