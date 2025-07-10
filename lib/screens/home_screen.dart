// lib/screens/home_screen.dart - DÜZELTILMIŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/achievement_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/food_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/advanced_step_counter_service.dart';
import '../services/calorie_service.dart';
import '../utils/colors.dart';
import '../widgets/activity_calendar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/expandable_activity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AdvancedStepCounterService _stepCounter = AdvancedStepCounterService();
  DateTime _selectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeStepCounter();
  }

  Future<void> _initializeStepCounter() async {
    await _stepCounter.initialize();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Sistem UI rengini dinamik olarak ayarla
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: Consumer5<UserProvider, FoodProvider, ExerciseProvider, AchievementProvider, ThemeProvider>(
                  builder: (context, userProvider, foodProvider, exerciseProvider, achievementProvider, themeProvider, child) {
                    final user = userProvider.user;
                    final dailyIntakeCalories = foodProvider.getDailyCalories(_selectedDate);
                    final dailyBurnedCalories = exerciseProvider.getDailyBurnedCalories(_selectedDate);
                    final dailyWaterIntake = userProvider.getDailyWaterIntake(_selectedDate);
                    final unlockedAchievements = achievementProvider.achievements.where((a) => a.isUnlocked).length;
                    
                    final dailyWaterTarget = user != null
                        ? CalorieService.calculateDailyWaterNeeds(weight: user.weight, activityLevel: user.activityLevel)
                        : 2.0;

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.menu, size: 28, color: isDarkMode ? Colors.white : Colors.black),
                                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                    children: const [
                                      TextSpan(text: 'F', style: TextStyle(color: AppColors.primaryGreen, fontSize: 48)),
                                      TextSpan(text: 'ormda'),
                                      TextSpan(text: 'K', style: TextStyle(color: AppColors.primaryGreen, fontSize: 48)),
                                      TextSpan(text: 'al'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 28, color: isDarkMode ? Colors.white : Colors.black),
                                  onPressed: () => themeProvider.toggleTheme(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Takvim ile başlık arasındaki boşluk
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),

                        // Calendar
                        SliverToBoxAdapter(
                          child: ActivityCalendar(
                            mode: CalendarMode.activity,
                            showStats: false, 
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                          ),
                        ),
                        
                        // Activities Header ve Paylaş Butonu
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Aktivitelerim', 
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black)),
                                // Günlük Özet Paylaşım Butonu
                                IconButton(
                                  icon: const Icon(Icons.share, size: 28, color: AppColors.primaryGreen),
                                  onPressed: () => Navigator.pushNamed(context, '/daily_summary'),
                                  tooltip: 'Günlük Özetimi Paylaş',
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Activity Cards
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // Advanced Step Counter Card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildAdvancedStepCounterCard(isDarkMode),
                              ),
                              const SizedBox(height: 7),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ExpandableActivityCard(
                                  title: 'Başarımlar',
                                  subtitle: 'Kazanılan rozet ve madalyalar',
                                  value: unlockedAchievements.toString(),
                                  unit: 'adet',
                                  icon: Icons.emoji_events,
                                  color: Colors.amber,
                                  type: ActivityCardType.achievements,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ExpandableActivityCard(
                                  title: 'Fitness Kalori',
                                  subtitle: 'Bugün yakılan kalori',
                                  value: dailyBurnedCalories.toInt().toString(),
                                  unit: 'kal',
                                  icon: Icons.fitness_center,
                                  color: AppColors.primaryGreen,
                                  type: ActivityCardType.fitness,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ExpandableActivityCard(
                                  title: 'Yemek Kalori',
                                  subtitle: 'Bugün alınan kalori',
                                  value: dailyIntakeCalories.toStringAsFixed(0),
                                  unit: 'kal',
                                  icon: Icons.restaurant,
                                  color: AppColors.calorieColor,
                                  type: ActivityCardType.food,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ExpandableActivityCard(
                                  title: 'Kalori Takip',
                                  subtitle: 'Net kalori dengesi',
                                  value: (dailyIntakeCalories - dailyBurnedCalories).toStringAsFixed(0),
                                  unit: 'kal',
                                  icon: Icons.track_changes,
                                  color: Colors.blueAccent,
                                  type: ActivityCardType.calorieTracking,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ExpandableActivityCard(
                                  title: 'Su Tüketimi',
                                  subtitle: '${(dailyWaterTarget * 1000).toInt()} ml hedef',
                                  value: (dailyWaterIntake * 1000).toInt().toString(),
                                  unit: 'ml',
                                  icon: Icons.water_drop,
                                  color: AppColors.timeColor,
                                  type: ActivityCardType.water,
                                ),
                              ),
                              // Navigation bar boşluğu
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStepCounterCard(bool isDarkMode) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final stepGoal = user?.dailyStepGoal ?? 6000;
        
        return ListenableBuilder(
          listenable: _stepCounter,
          builder: (context, child) {
            final todaySteps = _stepCounter.todaySteps;
            final isWalking = _stepCounter.isWalking;
            final progress = (todaySteps / stepGoal).clamp(0.0, 1.0);
            
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/step_details'),
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, 
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.stepColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWalking ? Icons.directions_walk : Icons.accessibility_new, 
                              color: AppColors.stepColor, 
                              size: 28
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Günlük Adımlar', 
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                                    if (isWalking) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.stepColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Yürüyor',
                                          style: TextStyle(
                                            color: AppColors.stepColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hedef: $stepGoal adım', 
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color
                                  )
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                todaySteps.toString(), 
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold, 
                                  color: AppColors.stepColor
                                )
                              ),
                              Text(
                                'adım', 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.stepColor),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}% tamamlandı',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${stepGoal - todaySteps > 0 ? stepGoal - todaySteps : 0} kaldı',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshData() async {
    try {
      await Future.wait([
        Provider.of<UserProvider>(context, listen: false).loadUser(),
        Provider.of<FoodProvider>(context, listen: false).loadData(),
        Provider.of<ExerciseProvider>(context, listen: false).loadData(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler güncellendi'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Step counter'ı dispose etme - arka planda çalışmaya devam etsin
    super.dispose();
  }
}