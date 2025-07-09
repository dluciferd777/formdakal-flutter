// lib/screens/home_screen.dart - HAMBURGER MENÜ + TEMA DÜZELTMESİ
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
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: AppColors.primaryGreen,
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
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Hamburger Menü - Beyaz temada görünür
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.grey.shade800 
                                        : AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isDarkMode 
                                        ? null 
                                        : Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.menu_rounded, 
                                      size: 28, 
                                      color: isDarkMode 
                                          ? Colors.white 
                                          : AppColors.primaryGreen,
                                    ),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                    tooltip: 'Menüyü Aç',
                                  ),
                                ),
                                
                                // Logo
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold, 
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'F', 
                                        style: TextStyle(
                                          color: AppColors.primaryGreen, 
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(text: 'ormda'),
                                      TextSpan(
                                        text: 'K', 
                                        style: TextStyle(
                                          color: AppColors.primaryGreen, 
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(text: 'al'),
                                    ],
                                  ),
                                ),
                                
                                // Tema değiştirme butonu
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.grey.shade800 
                                        : AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isDarkMode 
                                        ? null 
                                        : Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      themeProvider.isDarkMode 
                                          ? Icons.light_mode_rounded 
                                          : Icons.dark_mode_rounded, 
                                      size: 28, 
                                      color: isDarkMode 
                                          ? Colors.yellow.shade600 
                                          : AppColors.primaryGreen,
                                    ),
                                    onPressed: () {
                                      themeProvider.toggleTheme();
                                      // Haptic feedback
                                      HapticFeedback.lightImpact();
                                    },
                                    tooltip: isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Boşluk
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 20),
                        ),

                        // Kullanıcı Karşılama Mesajı
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDarkMode 
                                      ? [AppColors.primaryGreen.withOpacity(0.3), AppColors.primaryGreen.withOpacity(0.1)]
                                      : [AppColors.primaryGreen.withOpacity(0.1), AppColors.primaryGreen.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.waving_hand_rounded,
                                    color: AppColors.primaryGreen,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Merhaba ${user?.name ?? 'Kullanıcı'}!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bugün hedeflerine ulaşmak için hazır mısın?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Calendar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: ActivityCalendar(
                              mode: CalendarMode.activity,
                              showStats: false, 
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                        ),
                        
                        // Activities Header ve Paylaş Butonu
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bugünkü Aktivitelerim', 
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700, 
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.share_rounded, size: 22, color: Colors.white),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/daily_summary');
                                      HapticFeedback.mediumImpact();
                                    },
                                    tooltip: 'Günlük Özetimi Paylaş',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                      // Activity Cards
SliverToBoxAdapter(
  child: Column(
    children: [
      // Step Counter Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const StepCounterCard(),
        ),
      ),
      
      const SizedBox(height: 12),
      
      // Başarımlar Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
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
      ),
      
      const SizedBox(height: 12),
      
      // Fitness Kalori Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
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
      ),
      
      const SizedBox(height: 12),
      
      // Yemek Kalori Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
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
      ),
      
      const SizedBox(height: 12),
      
      // Kalori Takip Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
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
      ),
      
      const SizedBox(height: 12),
      
      // Su Tüketimi Card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
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
      HapticFeedback.lightImpact();
      
      await Future.wait([
        Provider.of<UserProvider>(context, listen: false).loadUser(),
        Provider.of<FoodProvider>(context, listen: false).loadData(),
        Provider.of<ExerciseProvider>(context, listen: false).loadData(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Veriler başarıyla güncellendi'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Güncelleme hatası: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}