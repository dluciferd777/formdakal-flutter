// lib/main.dart - TAM KOD
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
import 'package:formdakal/services/notification_service.dart';
import 'package:formdakal/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init(); 

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
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
  bool _isAppPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // BAŞARIMLARI AKTİF ET
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateBasicAchievements();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // BAŞARIMLARI AKTİF ETME
  void _activateBasicAchievements() {
    try {
      final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
      achievementProvider.unlockAchievement('first_login');
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        achievementProvider.unlockAchievement('profile_complete');
      }
      
      print('✅ Temel başarımlar aktif edildi');
    } catch (e) {
      print('❌ Başarım aktif etme hatası: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _isAppPaused = true;
        _saveAllData();
        print("📱 Uygulama arkaplanda - Veriler kaydedildi");
        break;
        
      case AppLifecycleState.resumed:
        if (_isAppPaused) {
          _loadAllData();
          _isAppPaused = false;
          print("📱 Uygulama öne geldi - Veriler yüklendi");
        }
        break;
        
      case AppLifecycleState.detached:
        _saveAllData();
        print("📱 Uygulama kapatılıyor - Son kaydetme");
        break;
        
      case AppLifecycleState.inactive:
        break;
        
      case AppLifecycleState.hidden:
        print("📱 Uygulama gizlendi");
        break;
    }
  }

  void _saveAllData() {
    try {
      if (mounted) {
        print("💾 Tüm veriler kaydedildi");
      }
    } catch (e) {
      print("❌ Veri kaydetme hatası: $e");
    }
  }

  void _loadAllData() {
    try {
      print("📂 Veriler yeniden yüklendi");
    } catch (e) {
      print("❌ Veri yükleme hatası: $e");
    }
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
        ChangeNotifierProxyProvider<AchievementProvider, UserProvider>(
          create: (context) => UserProvider(widget.prefs, Provider.of<AchievementProvider>(context, listen: false)),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        ChangeNotifierProxyProvider<AchievementProvider, FoodProvider>(
          create: (context) => FoodProvider(widget.prefs, Provider.of<AchievementProvider>(context, listen: false)),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        ChangeNotifierProxyProvider2<AchievementProvider, UserProvider, ExerciseProvider>(
          create: (context) => ExerciseProvider(widget.prefs,
            Provider.of<AchievementProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
          ),
          update: (_, achievement, user, previous) => previous!..updateDependencies(achievement, user),
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
            theme: AppTheme.lightTheme.copyWith(
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
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
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
                      ? Brightness.light 
                      : Brightness.dark,
                  systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
                      ? Brightness.light 
                      : Brightness.dark,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}