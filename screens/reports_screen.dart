// lib/screens/reports_screen.dart - GELİŞTİRİLMİŞ GRAFİKLER
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weight_history_model.dart';
import '../providers/user_provider.dart';
import '../providers/food_provider.dart';
import '../providers/exercise_provider.dart';
import '../services/native_step_counter_service.dart'; // NativeStepCounterService import edildi
import '../utils/colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 7; // Varsayılan 7 gün

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Raporlar ve Grafikler'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen, // Temaya göre renk
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Kilo', icon: Icon(Icons.monitor_weight, size: 18)),
            Tab(text: 'Kalori', icon: Icon(Icons.local_fire_department, size: 18)),
            Tab(text: 'Aktivite', icon: Icon(Icons.fitness_center, size: 18)),
            Tab(text: 'Beslenme', icon: Icon(Icons.restaurant, size: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zaman filtresi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeFilter('7G', 7),
                  _buildTimeFilter('30G', 30),
                  _buildTimeFilter('90G', 90),
                  _buildTimeFilter('1Y', 365),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWeightChart(),
                  _buildCalorieChart(),
                  _buildActivityChart(),
                  _buildNutritionChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.weightHistory.length < 2) {
          return _buildEmptyChart('Kilo grafik çizmek için en az 2 kilo kaydı gereklidir.');
        }
        
        final filteredData = _filterDataByDays(userProvider.weightHistory);
        if (filteredData.isEmpty) {
          return _buildEmptyChart('Seçilen zaman aralığında veri bulunmuyor.');
        }

        return _buildChartCard(
          title: 'Kilo Değişimi',
          subtitle: '${filteredData.length} kayıt',
          chart: _buildLineChart(
            data: filteredData.map((e) => FlSpot(
              e.date.millisecondsSinceEpoch.toDouble(),
              e.weight,
            )).toList(),
            color: AppColors.primaryGreen,
            unit: 'kg',
          ),
        );
      },
    );
  }

  Widget _buildCalorieChart() {
    return Consumer2<FoodProvider, ExerciseProvider>(
      builder: (context, foodProvider, exerciseProvider, child) {
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: _selectedDays));
        
        List<FlSpot> intakeSpots = [];
        List<FlSpot> burnedSpots = [];
        
        for (int i = 0; i <= _selectedDays; i++) {
          final date = startDate.add(Duration(days: i));
          final intake = foodProvider.getDailyCalories(date);
          final burned = exerciseProvider.getDailyBurnedCalories(date);
          
          intakeSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), intake));
          burnedSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), burned));
        }

        return _buildChartCard(
          title: 'Kalori Dengesi',
          subtitle: 'Son $_selectedDays gün',
          chart: _buildMultiLineChart([
            LineChartBarData(
              spots: intakeSpots,
              color: AppColors.calorieColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.calorieColor.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: burnedSpots,
              color: AppColors.primaryGreen,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryGreen.withOpacity(0.1),
              ),
            ),
          ]),
          legend: [
            {'label': 'Alınan', 'color': AppColors.calorieColor},
            {'label': 'Yakılan', 'color': AppColors.primaryGreen},
          ],
        );
      },
    );
  }

  Widget _buildActivityChart() {
    return Consumer2<ExerciseProvider, NativeStepCounterService>( // NativeStepCounterService eklendi
      builder: (context, exerciseProvider, stepService, child) { // stepService parametresi eklendi
        // Aktivite verilerini topla
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: _selectedDays));
        
        List<FlSpot> stepsSpots = [];
        List<FlSpot> caloriesSpots = [];
        
        for (int i = 0; i <= _selectedDays; i++) {
          final date = startDate.add(Duration(days: i));
          // Adım sayısı NativeStepCounterService'ten alınacak
          final steps = stepService.dailySteps; // stepService.dailySteps kullanıldı
          final calories = exerciseProvider.getDailyBurnedCalories(date);
          
          stepsSpots.add(FlSpot(i.toDouble(), steps.toDouble()));
          caloriesSpots.add(FlSpot(i.toDouble(), calories));
        }

        return _buildChartCard(
          title: 'Aktivite Özeti',
          subtitle: 'Son $_selectedDays gün',
          chart: Column(
            children: [
              Expanded(
                child: _buildBarChart(
                  data: caloriesSpots,
                  color: AppColors.primaryGreen,
                  title: 'Yakılan Kalori',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildBarChart(
                  data: stepsSpots,
                  color: AppColors.stepColor,
                  title: 'Adım Sayısı',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionChart() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final today = DateTime.now();
        final protein = foodProvider.getDailyProtein(today);
        final carbs = foodProvider.getDailyCarbs(today);
        final fat = foodProvider.getDailyFat(today);
        
        final total = protein + carbs + fat;
        if (total == 0) {
          return _buildEmptyChart('Bugün beslenme verisi girilmemiş.');
        }

        return _buildChartCard(
          title: 'Makro Besin Dağılımı',
          subtitle: 'Bugünkü toplam: ${total.toInt()}g',
          chart: _buildPieChart([
            PieChartSectionData(
              value: protein,
              title: 'Protein\n${protein.toInt()}g',
              color: AppColors.primaryGreen,
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PieChartSectionData(
              value: carbs,
              title: 'Karb.\n${carbs.toInt()}g',
              color: Colors.orange,
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            PieChartSectionData(
              value: fat,
              title: 'Yağ\n${fat.toInt()}g',
              color: AppColors.error,
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
    List<Map<String, dynamic>>? legend,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (legend != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: legend.map((item) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['label'],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )).toList(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart({
    required List<FlSpot> data,
    required Color color,
    required String unit,
  }) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}$unit',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('d/M').format(date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLineChart(List<LineChartBarData> lines) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(
                  DateFormat('d/M').format(date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lines,
      ),
    );
  }

  Widget _buildBarChart({
    required List<FlSpot> data,
    required Color color,
    required String title,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: data.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.y,
                      color: color,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(List<PieChartSectionData> sections) {
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  List<WeightHistoryModel> _filterDataByDays(List<WeightHistoryModel> data) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedDays));
    return data.where((item) => item.date.isAfter(startDate)).toList();
  }
}
