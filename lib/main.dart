// lib/main.dart - PERMISSION & ERROR HANDLING ENTEGRASYONU
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
import 'package:formdakal/services/permission_service.dart';
import 'package:formdakal/services/error_handler.dart';
import 'package:formdakal/utils/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Comprehensive app initialization with error handling
  await _initializeApp();
}

/// Initialize app with proper error handling and services
Future<void> _initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('🚀 FormdaKal başlatılıyor...');
    
    // Initialize core services
    await _initializeCoreServices();
    
    // Initialize UI
    _initializeUI();
    
    // Load shared preferences
    final prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences yüklendi');
    
    // Start the app
    runApp(MyApp(prefs: prefs));
    print('✅ FormdaKal başarıyla başlatıldı');
    
  } catch (error) {
    print('❌ Kritik başlatma hatası: $error');
    
    // Fallback: Start app with basic configuration
    try {
      final prefs = await SharedPreferences.getInstance();
      runApp(MyApp(prefs: prefs, hasError: true));
    } catch (fallbackError) {
      print('❌ Fallback başlatma da başarısız: $fallbackError');
      // Last resort: show basic error screen
      runApp(const ErrorApp());
    }
  }
}

/// Initialize core services
Future<void> _initializeCoreServices() async {
  // Initialize error handler first
  ErrorHandler();
  print('✅ Error handler başlatıldı');
  
  // Initialize permission service
  await PermissionService().init();
  print('✅ Permission service başlatıldı');
  
  // Initialize notification service
  await NotificationService().init();
  print('✅ Notification service başlatıldı');
  
  // Initialize date formatting
  await initializeDateFormatting('tr_TR', null);
  print('✅ Türkçe tarih formatı başlatıldı');
}

/// Initialize UI settings
void _initializeUI() {
  // System UI configuration
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
  
  print('✅ System UI yapılandırıldı');
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  final bool hasError;

  const MyApp({
    super.key, 
    required this.prefs,
    this.hasError = false,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isAppPaused = false;
  bool _isInitialized = false;
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    // Set error handler context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorHandler().setContext(context);
    });
    
    print('📱 App lifecycle observer eklendi');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ErrorHandler().dispose();
    print('📱 App lifecycle observer kaldırıldı');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!_isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        print("📱 Uygulama geçici olarak aktif değil");
        break;
      case AppLifecycleState.hidden:
        print("📱 Uygulama gizlendi");
        break;
    }
  }

  void _handleAppPaused() {
    _isAppPaused = true;
    _saveAllData();
    print("📱 Uygulama arkaplanda - Veriler kaydedildi");
  }

  void _handleAppResumed() {
    if (_isAppPaused) {
      _loadAllData();
      _checkPermissionsIfNeeded();
      _isAppPaused = false;
      print("📱 Uygulama öne geldi - Veriler yüklendi");
    }
  }

  void _handleAppDetached() {
    _saveAllData();
    print("📱 Uygulama kapatılıyor - Son kaydetme");
  }

  void _saveAllData() {
    ErrorHandler().executeWithLoading(
      'app_save',
      () async {
        if (mounted && context.mounted) {
          // Force save all providers
          final exerciseProvider = context.read<ExerciseProvider>();
          await exerciseProvider.forceSave();
          print("💾 Tüm veriler kaydedildi");
        }
      },
      errorContext: 'Veri kaydetme',
      showErrorDialog: false,
    );
  }

  void _loadAllData() {
    ErrorHandler().executeWithLoading(
      'app_load',
      () async {
        if (mounted && context.mounted) {
          await context.read<ExerciseProvider>().loadData();
          print("📂 Veriler yeniden yüklendi");
        }
      },
      errorContext: 'Veri yükleme',
      showErrorDialog: false,
    );
  }

  void _checkPermissionsIfNeeded() {
    if (!_permissionsChecked) {
      _requestEssentialPermissions();
      _permissionsChecked = true;
    }
  }

  Future<void> _requestEssentialPermissions() async {
    if (!mounted) return;
    
    try {
      final success = await PermissionService().requestEssentialPermissions(context);
      if (success) {
        print("✅ Temel izinler verildi");
      } else {
        print("⚠️ Bazı izinler reddedildi");
      }
    } catch (e) {
      print("❌ İzin kontrolü hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error app if initialization failed
    if (widget.hasError) {
      return _buildErrorApp();
    }

    return MultiProvider(
      providers: [
        // Basic providers
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider<MeasurementProvider>(create: (_) => MeasurementProvider(widget.prefs)),
        ChangeNotifierProvider<ProgressPhotoProvider>(create: (_) => ProgressPhotoProvider(widget.prefs)),
        ChangeNotifierProvider<AchievementProvider>(create: (_) => AchievementProvider(widget.prefs)),
        ChangeNotifierProvider<ReminderProvider>(create: (_) => ReminderProvider(widget.prefs)),
        
        // Dependent providers
        ChangeNotifierProxyProvider<AchievementProvider, UserProvider>(
          create: (context) => UserProvider(
            widget.prefs, 
            Provider.of<AchievementProvider>(context, listen: false)
          ),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        
        ChangeNotifierProxyProvider<AchievementProvider, FoodProvider>(
          create: (context) => FoodProvider(
            widget.prefs, 
            Provider.of<AchievementProvider>(context, listen: false)
          ),
          update: (_, achievement, previous) => previous!..updateDependencies(achievement),
        ),
        
        ChangeNotifierProxyProvider2<AchievementProvider, UserProvider, ExerciseProvider>(
          create: (context) => ExerciseProvider(
            widget.prefs,
            Provider.of<AchievementProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
          ),
          update: (_, achievement, user, previous) => previous!..updateDependencies(achievement, user),
        ),
        
        ChangeNotifierProxyProvider3<AchievementProvider, UserProvider, ExerciseProvider, WorkoutPlanProvider>(
          create: (context) => WorkoutPlanProvider(
            widget.prefs,
            Provider.of<AchievementProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
            Provider.of<ExerciseProvider>(context, listen: false),
          ),
          update: (_, achievement, user, exercise, previous) => 
            previous!..updateDependencies(achievement, user, exercise),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FormdaKal',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            
            // Modern themes
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            
            home: const SplashScreen(),
            routes: _buildRoutes(),
            builder: _buildAppWrapper,
            
            // Error handling
            onGenerateRoute: _onGenerateRoute,
            onUnknownRoute: _onUnknownRoute,
          );
        },
      ),
    );
  }

  List<ChangeNotifierProvider> _buildProviders() {
    return [
      // Basic providers
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(widget.prefs)),
      ChangeNotifierProvider<MeasurementProvider>(create: (_) => MeasurementProvider(widget.prefs)),
      ChangeNotifierProvider<ProgressPhotoProvider>(create: (_) => ProgressPhotoProvider(widget.prefs)),
      ChangeNotifierProvider<AchievementProvider>(create: (_) => AchievementProvider(widget.prefs)),
      ChangeNotifierProvider<ReminderProvider>(create: (_) => ReminderProvider(widget.prefs)),
      
      // Dependent providers - using MultiProvider instead
    ];
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
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
      '/workout_plan_details': (context) => WorkoutPlanDetailsScreen(
        plan: ModalRoute.of(context)!.settings.arguments as WorkoutPlanModel
      ),
      '/select_exercise': (context) => const SelectExerciseScreen(),
      '/achievements': (context) => const AchievementsScreen(),
      '/step_details': (context) => const StepDetailsScreen(),
      '/daily_summary': (context) => const DailySummaryScreen(),
    };
  }

  Widget _buildAppWrapper(BuildContext context, Widget? child) {
    return SafeWrapper(
      errorContext: 'Ana uygulama',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    print('🔍 Route generate: ${settings.name}');
    return null; // Use default routing
  }

  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    print('❌ Bilinmeyen route: ${settings.name}');
    
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Sayfa bulunamadı'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home', 
                  (route) => false,
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorApp() {
    return MaterialApp(
      title: 'FormdaKal - Hata',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulama Başlatılamadı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen uygulamayı yeniden başlatın',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => SystemNavigator.pop(),
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Başlat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback error app for critical failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormdaKal - Kritik Hata',
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 72,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kritik Hata',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı.\nLütfen cihazınızı yeniden başlatın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Uygulamayı Kapat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}