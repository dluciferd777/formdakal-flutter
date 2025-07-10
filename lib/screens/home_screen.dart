// lib/screens/home_screen_optimized.dart - PERFORMANS OPTİMİZE EDİLMİŞ
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
import '../widgets/advanced_step_counter_card.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/expandable_activity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();
  
  // PERFORMANS İYİLEŞTİRME: Animation controller'ları optimize et
  late AnimationController _refreshController;
  
  // PERFORMANS İYİLEŞTİRME: Rebuild azaltma için cache
  Map<String, dynamic>? _cachedData;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // PERFORMANS: Tek animation controller kullan
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // PERFORMANS: Adım sayar servisini optimize başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStepCounterOptimized();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // PERFORMANS: Lazy initialization
  Future<void> _initializeStepCounterOptimized() async {
    try {
      final stepService = Provider.of<AdvancedStepCounterService>(context, listen: false);
      if (!stepService.isServiceActive) {
        await stepService.initialize();
        print('✅ Adım sayar servisi optimize başlatıldı');
      }
    } catch (e) {
      print('❌ Adım sayar başlatma hatası: $e');
    }
  }

  // PERFORMANS: Veri cache sistemi
  Map<String, dynamic> _getCachedOrFreshData(
    UserProvider userProvider, 
    FoodProvider foodProvider, 
    ExerciseProvider exerciseProvider, 
    AchievementProvider achievementProvider
  ) {
    final now = DateTime.now();
    
    // Cache kontrolü
    if (_cachedData != null && 
        _lastCacheTime != null && 
        now.difference(_lastCacheTime!).compareTo(_cacheValidDuration) < 0) {
      return _cachedData!;
    }
    
    // Yeni veri hesapla ve cache'le
    final data = {
      'dailyIntakeCalories': foodProvider.getDailyCalories(_selectedDate),
      'dailyBurnedCalories': exerciseProvider.getDailyBurnedCalories(_selectedDate),
      'dailyWaterIntake': userProvider.getDailyWaterIntake(_selectedDate),
      'unlockedAchievements': achievementProvider.achievements.where((a) => a.isUnlocked).length,
      'dailyWaterTarget': userProvider.user != null
          ? CalorieService.calculateDailyWaterNeeds(
              weight: userProvider.user!.weight, 
              activityLevel: userProvider.user!.activityLevel
            )
          : 2.0,
    };
    
    _cachedData = data;
    _lastCacheTime = now;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // PERFORMANS: Sistem UI güncellemeyi azalt
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
                onRefresh: _refreshDataOptimized,
                child: Consumer5<UserProvider, FoodProvider, ExerciseProvider, AchievementProvider, ThemeProvider>(
                  builder: (context, userProvider, foodProvider, exerciseProvider, achievementProvider, themeProvider, child) {
                    // PERFORMANS: Cache sistemini kullan
                    final data = _getCachedOrFreshData(userProvider, foodProvider, exerciseProvider, achievementProvider);

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      // PERFORMANS: Sliver'ları optimize et
                      slivers: [
                        // Header - PERFORMANS: Statik widget
                        SliverToBoxAdapter(
                          child: _buildHeaderOptimized(context, isDarkMode),
                        ),
                        
                        // Spacing
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),

                        // Calendar - PERFORMANS: Rebuild azaltma
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: ActivityCalendar(
                              mode: CalendarMode.activity,
                              showStats: false, 
                              onDateSelected: (date) {
                                if (date != _selectedDate) {
                                  setState(() {
                                    _selectedDate = date;
                                    // PERFORMANS: Cache temizle date değişince
                                    _cachedData = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        
                        // Activities Header
                        SliverToBoxAdapter(
                          child: _buildActivitiesHeaderOptimized(context, isDarkMode),
                        ),
                        
                        // Activity Cards - PERFORMANS: RepaintBoundary ekle
                        SliverToBoxAdapter(
                          child: _buildActivityCardsOptimized(context, data),
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

  // PERFORMANS: Statik header widget
  Widget _buildHeaderOptimized(BuildContext context, bool isDarkMode) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.menu, size: 28, color: isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            RepaintBoundary(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: isDarkMode ? Colors.white : Colors.black
                  ),
                  children: const [
                    TextSpan(text: 'F', style: TextStyle(color: AppColors.primaryGreen, fontSize: 48)),
                    TextSpan(text: 'ormda'),
                    TextSpan(text: 'K', style: TextStyle(color: AppColors.primaryGreen, fontSize: 48)),
                    TextSpan(text: 'al'),
                  ],
                ),
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode, 
                    size: 28, 
                    color: isDarkMode ? Colors.white : Colors.black
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // PERFORMANS: Statik activities header
  Widget _buildActivitiesHeaderOptimized(BuildContext context, bool isDarkMode) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitelerim', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600, 
                color: isDarkMode ? Colors.white : Colors.black
              )
            ),
            IconButton(
              icon: Icon(Icons.share, size: 28, color: AppColors.primaryGreen),
              onPressed: () => Navigator.pushNamed(context, '/daily_summary'),
              tooltip: 'Günlük Özetimi Paylaş',
            ),
          ],
        ),
      ),
    );
  }

  // PERFORMANS: Activity cards optimize
  Widget _buildActivityCardsOptimized(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        // Step Counter Card - PERFORMANS: RepaintBoundary
        RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const AdvancedStepCounterCard(),
          ),
        ),
        
        const SizedBox(height: 7),
        
        // Other cards - PERFORMANS: RepaintBoundary her birine
        ...List.generate(4, (index) {
          final cardData = _getCardData(index, data);
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
              child: ExpandableActivityCard(
                title: cardData['title'],
                subtitle: cardData['subtitle'],
                value: cardData['value'],
                unit: cardData['unit'],
                icon: cardData['icon'],
                color: cardData['color'],
                type: cardData['type'],
              ),
            ),
          );
        }),
        
        // Navigation bar boşluğu
        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
      ],
    );
  }

  // PERFORMANS: Card data helper
  Map<String, dynamic> _getCardData(int index, Map<String, dynamic> data) {
    switch (index) {
      case 0:
        return {
          'title': 'Başarımlar',
          'subtitle': 'Kazanılan rozet ve madalyalar',
          'value': data['unlockedAchievements'].toString(),
          'unit': 'adet',
          'icon': Icons.emoji_events,
          'color': Colors.amber,
          'type': ActivityCardType.achievements,
        };
      case 1:
        return {
          'title': 'Fitness Kalori',
          'subtitle': 'Bugün yakılan kalori',
          'value': data['dailyBurnedCalories'].toInt().toString(),
          'unit': 'kal',
          'icon': Icons.fitness_center,
          'color': AppColors.primaryGreen,
          'type': ActivityCardType.fitness,
        };
      case 2:
        return {
          'title': 'Yemek Kalori',
          'subtitle': 'Bugün alınan kalori',
          'value': data['dailyIntakeCalories'].toStringAsFixed(0),
          'unit': 'kal',
          'icon': Icons.restaurant,
          'color': AppColors.calorieColor,
          'type': ActivityCardType.food,
        };
      case 3:
        return {
          'title': 'Su Tüketimi',
          'subtitle': '${(data['dailyWaterTarget'] * 1000).toInt()} ml hedef',
          'value': (data['dailyWaterIntake'] * 1000).toInt().toString(),
          'unit': 'ml',
          'icon': Icons.water_drop,
          'color': AppColors.timeColor,
          'type': ActivityCardType.water,
        };
      default:
        return {
          'title': 'Kalori Takip',
          'subtitle': 'Net kalori dengesi',
          'value': (data['dailyIntakeCalories'] - data['dailyBurnedCalories']).toStringAsFixed(0),
          'unit': 'kal',
          'icon': Icons.track_changes,
          'color': Colors.blueAccent,
          'type': ActivityCardType.calorieTracking,
        };
    }
  }

  // PERFORMANS: Optimize refresh
  Future<void> _refreshDataOptimized() async {
    _refreshController.forward().then((_) => _refreshController.reset());
    
    try {
      // PERFORMANS: Cache temizle
      _cachedData = null;
      
      await Future.wait([
        Provider.of<UserProvider>(context, listen: false).loadUser(),
        Provider.of<FoodProvider>(context, listen: false).loadData(),
        Provider.of<ExerciseProvider>(context, listen: false).loadData(),
        _initializeStepCounterOptimized(),
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