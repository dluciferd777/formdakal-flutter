// lib/main.dart (PROVIDER DÜZELTİLMİŞ VERSİYON)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:formdakal/models/workout_plan_model.dart';
import 'package:formdakal/providers/achievement_provider.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/food_provider.dart';
import 'package:formdakal/providers/measurement_provider.dart';
import 'package:formdakal/providers/progress_photo_provider.dart';
import 'package:formdakal/providers/reminder_provider.dart';
import 'package:formdakal/providers/theme_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/providers/workout_plan_provider.dart';
import 'package:formdakal/services/notification_service.dart';
import 'package:formdakal/services/native_step_counter_service.dart';
import 'package:formdakal/screens/achievements_screen.dart';
import 'package:formdakal/screens/calorie_tracking_screen.dart';
import 'package:formdakal/screens/daily_summary_screen.dart';
import 'package:formdakal/screens/fitness_screen.dart';
import 'package:formdakal/screens/food_calories_screen.dart';
import 'package:formdakal/screens/home_screen.dart';
import 'package:formdakal/screens/measurement_screen.dart';
import 'package:formdakal/screens/onboarding_screen.dart';
import 'package:formdakal/screens/profile_screen.dart';
import 'package:formdakal/screens/progress_photos_screen.dart';
import 'package:formdakal/screens/reminder_screen.dart';
import 'package:formdakal/screens/reports_screen.dart';
import 'package:formdakal/screens/select_exercise_screen.dart';
import 'package:formdakal/screens/splash_screen.dart';
import 'package:formdakal/screens/step_details_screen.dart';
import 'package:formdakal/screens/workout_plan_details_screen.dart';
import 'package:formdakal/screens/workout_plans_list_screen.dart';
import 'package:formdakal/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// GLOBAL INSTANCE: NativeStepCounterService'i burada tanımlıyoruz
final NativeStepCounterService stepCounterService = NativeStepCounterService();

Future<void> requestEssentialPermissions() async {
  var activityStatus = await Permission.activityRecognition.status;
  if (!activityStatus.isGranted) {
    activityStatus = await Permission.activityRecognition.request();
  }

  var notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
  }

  if (activityStatus.isGranted) {
    print("✅ Fiziksel Aktivite izni alındı.");
  } else {
    print("❌ Fiziksel Aktivite izni reddedildi.");
  }
  
  if (notificationStatus.isGranted) {
    print("✅ Bildirim izni alındı.");
  } else {
    print("❌ Bildirim izni reddedildi.");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await requestEssentialPermissions();
  
  await NotificationService().init(); 

  // NativeStepCounterService'i runApp'tan önce başlat ve verilerini yükle
  await stepCounterService.initialize(); // Bu satır eklendi ve await kullanıldı

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  
  await initializeDateFormatting('tr_TR', null);
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => ReminderProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => MeasurementProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => ProgressPhotoProvider(widget.prefs)),
        ChangeNotifierProvider(create: (_) => AchievementProvider(widget.prefs)),
        
        // NativeStepCounterService'in başlatılmış örneğini sağlıyoruz
        ChangeNotifierProvider.value(value: stepCounterService),
        
        ChangeNotifierProxyProvider<AchievementProvider, UserProvider>(
          create: (context) => UserProvider(widget.prefs, Provider.of<AchievementProvider>(context, listen: false)),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        ChangeNotifierProxyProvider3<AchievementProvider, UserProvider, NativeStepCounterService, ExerciseProvider>(
          create: (context) => ExerciseProvider(widget.prefs,
            Provider.of<AchievementProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
            Provider.of<NativeStepCounterService>(context, listen: false),
          ),
          update: (_, achievement, user, nativeStepCounterService, previous) => previous!..updateDependencies(achievement, user, nativeStepCounterService),
        ),
        ChangeNotifierProxyProvider<AchievementProvider, FoodProvider>(
          create: (context) => FoodProvider(widget.prefs, Provider.of<AchievementProvider>(context, listen: false)),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        ChangeNotifierProxyProvider3<AchievementProvider, UserProvider, ExerciseProvider, WorkoutPlanProvider>(
          create: (context) => WorkoutPlanProvider(widget.prefs,
            Provider.of<AchievementProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
            Provider.of<ExerciseProvider>(context, listen: false),
          ),
          update: (_, achievement, user, exercise, previous) => previous!..updateDependencies(achievement, user, exercise),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FormdaKal',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/fitness': (context) => const FitnessScreen(),
              '/food_calories': (context) => const FoodCaloriesScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/calorie_tracking': (context) => const CalorieTrackingScreen(),
              '/reminders': (context) => const ReminderScreen(),
              '/measurements': (context) => const MeasurementScreen(),
              '/progress_photos': (context) => const ProgressPhotosScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/workout_plans': (context) => const WorkoutPlansListScreen(),
              '/workout_plan_details': (context) => WorkoutPlanDetailsScreen(plan: ModalRoute.of(context)!.settings.arguments as WorkoutPlanModel),
              '/select_exercise': (context) => const SelectExerciseScreen(),
              '/achievements': (context) => const AchievementsScreen(),
              '/step_details': (context) => const StepDetailsScreen(),
              '/daily_summary': (context) => const DailySummaryScreen(),
            },
          );
        },
      ),
    );
  }
}
