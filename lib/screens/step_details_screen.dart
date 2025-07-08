// lib/screens/step_details_screen.dart - OVERFLOW HATASI DÜZELTİLDİ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/user_provider.dart';
import '../utils/colors.dart';
import '../widgets/activity_ring_painter.dart';
import 'package:fl_chart/fl_chart.dart';

class StepDetailsScreen extends StatefulWidget {
  const StepDetailsScreen({super.key});

  @override
  State<StepDetailsScreen> createState() => _StepDetailsScreenState();
}

class _StepDetailsScreenState extends State<StepDetailsScreen> 
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _ringAnimationController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Ring animasyonu
    _ringAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringAnimationController,
      curve: Curves.elasticOut,
    );
    
    // Animasyonu başlat
    _ringAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ringAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: Consumer2<ExerciseProvider, UserProvider>(
        builder: (context, exerciseProvider, userProvider, child) {
          final steps = exerciseProvider.dailySteps;
          final activeMinutes = exerciseProvider.dailyActiveMinutes;
          final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
          final user = userProvider.user;
          
          // Dinamik hedefler (kullanıcı profiline göre)
          final stepGoal = user?.dailyStepGoal ?? 10000;
          final minuteGoal = user?.dailyMinuteGoal ?? 60;
          final calorieGoal = (user?.dailyCalorieNeeds ?? 2000) * 0.2; // %20'si egzersizden
          
          final distanceKm = (steps * 0.75) / 1000;
          
          final stepProgress = (steps / stepGoal).clamp(0.0, 1.0);
          final minuteProgress = (activeMinutes / minuteGoal).clamp(0.0, 1.0);
          final calorieProgress = (burnedCalories / calorieGoal).clamp(0.0, 1.0);

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 60, // Yükseklik azaltıldı
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F7),
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Adım Sayar', // Başlık değiştirildi
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24, // Font boyutu küçültüldü
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 12), // Padding azaltıldı
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                // Ana Activity Ring - Boyut ve padding azaltıldı
                Container(
                  margin: const EdgeInsets.all(16), // Margin azaltıldı
                  padding: const EdgeInsets.all(20), // Padding azaltıldı
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDarkMode ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Ring Chart - Boyut azaltıldı
                      AnimatedBuilder(
                        animation: _ringAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 240, // 280'den 240'a azaltıldı
                            height: 240, // 280'den 240'a azaltıldı
                            child: CustomPaint(
                              painter: ActivityRingPainter(
                                outerProgress: stepProgress * _ringAnimation.value,
                                middleProgress: minuteProgress * _ringAnimation.value,
                                innerProgress: calorieProgress * _ringAnimation.value,
                                outerColor: AppColors.stepColor,
                                middleColor: AppColors.timeColor,
                                innerColor: AppColors.calorieColor,
                                showGlow: true,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_walk_rounded,
                                      color: AppColors.stepColor,
                                      size: 40, // 48'den 40'a azaltıldı
                                    ),
                                    const SizedBox(height: 6), // 8'den 6'ya azaltıldı
                                    Text(
                                      steps.toString(),
                                      style: TextStyle(
                                        fontSize: 36, // 44'ten 36'ya azaltıldı
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'ADIM',
                                      style: TextStyle(
                                        fontSize: 14, // 16'dan 14'e azaltıldı
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6), // 8'den 6'ya azaltıldı
                                    Text(
                                      '${stepGoal.toString()} hedef',
                                      style: TextStyle(
                                        fontSize: 12, // 14'ten 12'ye azaltıldı
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24), // 32'den 24'e azaltıldı
                      
                      // Stats Row - Boyut optimizasyonu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModernStat(
                            context,
                            'Etkin Dakika',
                            activeMinutes.toString(),
                            AppColors.timeColor,
                            '${minuteGoal.toInt()}dk',
                            minuteProgress,
                            isDarkMode,
                          ),
                          Container(
                            width: 1,
                            height: 50, // 60'tan 50'ye azaltıldı
                            color: Colors.grey.shade300,
                          ),
                          _buildModernStat(
                            context,
                            'Kalori',
                            burnedCalories.toInt().toString(),
                            AppColors.calorieColor,
                            '${calorieGoal.toInt()}kal',
                            calorieProgress,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tab Bar - Margin azaltıldı
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16), // 20'den 16'ya azaltıldı
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDarkMode ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primaryGreen,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    onTap: (index) => HapticFeedback.selectionClick(),
                    tabs: const [
                      Tab(text: 'Bugün'),
                      Tab(text: '7 Gün'),
                      Tab(text: '30 Gün'),
                    ],
                  ),
                ),
                
                // Tab Content - Expanded ile overflow önlendi
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16), // Alt padding eklendi
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Bugün
                        _buildTodayStats(context, distanceKm, isDarkMode),
                        // 7 Gün
                        _buildWeeklyChart(context, exerciseProvider, isDarkMode),
                        // 30 Gün
                        _buildMonthlyChart(context, exerciseProvider, isDarkMode),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    String target,
    double progress,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        // Progress Circle - Boyut azaltıldı
        SizedBox(
          width: 40, // 50'den 40'a azaltıldı
          height: 40, // 50'den 40'a azaltıldı
          child: CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 3, // 4'ten 3'e azaltıldı
          ),
        ),
        const SizedBox(height: 8), // 12'den 8'e azaltıldı
        Text(
          value,
          style: TextStyle(
            fontSize: 20, // 24'ten 20'ye azaltıldı
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 2), // 4'ten 2'ye azaltıldı
        Text(
          label,
          style: TextStyle(
            fontSize: 12, // 14'ten 12'ye azaltıldı
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          target,
          style: TextStyle(
            fontSize: 10, // 12'den 10'a azaltıldı
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(BuildContext context, double distanceKm, bool isDarkMode) {
    return SingleChildScrollView( // ScrollView eklendi
      child: Container(
        margin: const EdgeInsets.all(16), // 20'den 16'ya azaltıldı
        padding: const EdgeInsets.all(20), // 24'ten 20'ye azaltıldı
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // MainAxisSize eklendi
          children: [
            Text(
              'Bugünkü Detaylar',
              style: TextStyle(
                fontSize: 18, // 20'den 18'e azaltıldı
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16), // 20'den 16'ya azaltıldı
            _buildStatRow(context, Icons.map_rounded, 'Mesafe', '${distanceKm.toStringAsFixed(2)} km', isDarkMode),
            _buildStatRow(context, Icons.speed_rounded, 'Ortalama Hız', '${(distanceKm * 60 / 24).toStringAsFixed(1)} km/h', isDarkMode),
            _buildStatRow(context, Icons.trending_up_rounded, 'En Aktif Saat', '14:00 - 15:00', isDarkMode),
            _buildStatRow(context, Icons.timer_rounded, 'Toplam Süre', '${(DateTime.now().hour - 6)} saat aktif', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // 16'dan 12'ye azaltıldı
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // 8'den 6'ya azaltıldı
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 18), // 20'den 18'e azaltıldı
          ),
          const SizedBox(width: 12), // 16'dan 12'ye azaltıldı
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14, // 16'dan 14'e azaltıldı
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, // 16'dan 14'e azaltıldı
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, ExerciseProvider exerciseProvider, bool isDarkMode) {
    // 7 günlük veri simülasyonu
    final weeklyData = List.generate(7, (index) {
      return FlSpot(index.toDouble(), (exerciseProvider.dailySteps * (0.7 + (index * 0.05))).toDouble());
    });

    return SingleChildScrollView( // ScrollView eklendi
      child: Container(
        margin: const EdgeInsets.all(16), // 20'den 16'ya azaltıldı
        padding: const EdgeInsets.all(20), // 24'ten 20'ye azaltıldı
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // MainAxisSize eklendi
          children: [
            Text(
              'Son 7 Gün Trendi',
              style: TextStyle(
                fontSize: 18, // 20'den 18'e azaltıldı
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16), // 20'den 16'ya azaltıldı
            SizedBox(
              height: 200, // Sabit yükseklik eklendi
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Pz', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.3)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primaryGreen,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.3),
                            AppColors.primaryGreen.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, ExerciseProvider exerciseProvider, bool isDarkMode) {
    return SingleChildScrollView( // ScrollView eklendi
      child: Container(
        margin: const EdgeInsets.all(16), // 20'den 16'ya azaltıldı
        padding: const EdgeInsets.all(20), // 24'ten 20'ye azaltıldı
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // MainAxisSize eklendi
          children: [
            Text(
              'Aylık Özet',
              style: TextStyle(
                fontSize: 18, // 20'den 18'e azaltıldı
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16), // 20'den 16'ya azaltıldı
            _buildStatRow(context, Icons.trending_up_rounded, 'Toplam Adım', '287,450', isDarkMode),
            _buildStatRow(context, Icons.local_fire_department_rounded, 'Toplam Kalori', '8,420 kal', isDarkMode),
            _buildStatRow(context, Icons.map_rounded, 'Toplam Mesafe', '215.6 km', isDarkMode),
            _buildStatRow(context, Icons.emoji_events_rounded, 'Hedeflenen Günler', '24/30 gün', isDarkMode),
            const SizedBox(height: 16), // 20'den 16'ya azaltıldı
            Container(
              padding: const EdgeInsets.all(12), // 16'dan 12'ye azaltıldı
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration_rounded, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu ay harika performans! Hedeflerinin %80\'ine ulaştın.',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 14, // Font boyutu eklendi
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}