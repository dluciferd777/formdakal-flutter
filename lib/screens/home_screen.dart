// lib/screens/home_screen.dart - EDGE-TO-EDGE VE PERFORMANS DÜZELTMESİ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/achievement_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/food_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/calorie_service.dart';
import '../utils/colors.dart';
import '../widgets/activity_calendar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/expandable_activity_card.dart';
import '../widgets/step_counter_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

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
      extendBody: true, // Body'yi navigation bar'a kadar uzat
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          // Ana içerik alanı
          Expanded(
            child: SafeArea(
              bottom: false, // Alt kısmı SafeArea korumasın
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
                        SliverToBoxAdapter(
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
                                  icon: Icon(Icons.share, size: 28, color: AppColors.primaryGreen),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const StepCounterCard(),
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
}