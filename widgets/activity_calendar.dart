// lib/widgets/activity_calendar.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/food_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:formdakal/widgets/activity_ring_painter.dart';
import 'package:formdakal/services/native_step_counter_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum CalendarMode { activity, macros }

class ActivityCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final CalendarMode mode;
  final bool showStats;

  const ActivityCalendar({
    super.key,
    required this.onDateSelected,
    this.mode = CalendarMode.activity,
    this.showStats = false,
  });

  @override
  State<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  late DateTime _selectedDate;
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentWeekStart = _getWeekStart(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(_selectedDate);
    });
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weeks * 7));
      _selectedDate = _currentWeekStart;
      widget.onDateSelected(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildHeader(theme),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildWeekDays(theme),
          ),
          if (widget.showStats) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildStatsRow(),
          ]
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            DateFormat('yyyy MMMM EEEE', 'tr_TR').format(_currentWeekStart),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _changeWeek(-1),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.chevron_left),
              ),
            ),
            GestureDetector(
              onTap: () => _changeWeek(1),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDays(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = _currentWeekStart.add(Duration(days: index));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildDayItem(date, theme),
        );
      }),
    );
  }

  Widget _buildDayItem(DateTime date, ThemeData theme) {
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        widget.onDateSelected(date);
      },
      child: Column(
        children: [
          Text(
            DateFormat('E', 'tr_TR').format(date).substring(0, 1),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: isToday ? AppColors.primaryGreen : null),
          ),
          const SizedBox(height: 6),
          _buildActivityRingForDay(date, isSelected),
          const SizedBox(height: 6),
          Container(
            height: 22,
            width: 22,
            decoration: isSelected
                ? const BoxDecoration(
                    color: AppColors.primaryGreen, shape: BoxShape.circle)
                : null,
            child: Center(
              child: Text(
                date.day.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRingForDay(DateTime date, bool isSelected) {
    return Consumer4<UserProvider, FoodProvider, ExerciseProvider, NativeStepCounterService>(
      builder: (context, userProvider, foodProvider, exerciseProvider, stepService, child) {
        double progress1 = 0, progress2 = 0, progress3 = 0;
        Color color1 = Colors.grey, color2 = Colors.grey, color3 = Colors.grey;

        final user = userProvider.user;

        if (widget.mode == CalendarMode.activity) {
          // ADIM, YEMEKTEKİ KALORİ (ALINAN), FİTNESS KALORİ (YAKILAN)
          
          // Adım verileri - şimdilik sadece bugün için adım sayar çalışıyor
          final bool isToday = DateUtils.isSameDay(date, DateTime.now());
          final steps = isToday ? stepService.dailySteps : 0; // Geçmiş günler için 0
          final stepGoal = user?.dailyStepGoal ?? 8000;
          
          // Yemekteki kalori (alınan kalori)
          final consumedCalories = foodProvider.getDailyCalories(date);
          final calorieIntakeGoal = user?.dailyCalorieNeeds ?? 2000;
          
          // Fitness kalori (yakılan kalori)
          final burnedCalories = exerciseProvider.getDailyBurnedCalories(date);
          final calorieBurnGoal = (user?.dailyCalorieNeeds ?? 2000) * 0.25;

          progress1 = (steps / stepGoal).clamp(0.0, 1.0);
          progress2 = (consumedCalories / calorieIntakeGoal).clamp(0.0, 1.0);
          progress3 = (burnedCalories / calorieBurnGoal).clamp(0.0, 1.0);

          color1 = AppColors.stepColor;       // Yeşil - Adım
          color2 = AppColors.calorieColor;    // Pembe/Kırmızı - Yemek Kalori (Alınan)
          color3 = Colors.orange;             // Turuncu - Fitness Kalori (Yakılan)
          
        } else if (widget.mode == CalendarMode.macros) {
          // PROTEİN, KARBONHİDRAT, YAĞ
          final protein = foodProvider.getDailyProtein(date);
          final carbs = foodProvider.getDailyCarbs(date);
          final fat = foodProvider.getDailyFat(date);

          final proteinGoal = user?.dailyProteinGoal ?? 100.0;
          final carbGoal = user?.dailyCarbGoal ?? 200.0;
          final fatGoal = user?.dailyFatGoal ?? 50.0;

          progress1 = (protein / proteinGoal).clamp(0.0, 1.0);
          progress2 = (carbs / carbGoal).clamp(0.0, 1.0);
          progress3 = (fat / fatGoal).clamp(0.0, 1.0);

          color1 = AppColors.primaryGreen;    // Yeşil - Protein
          color2 = Colors.orange;             // Turuncu - Karbonhidrat
          color3 = AppColors.error;           // Kırmızı - Yağ
        }

        return SizedBox(
          width: 45,
          height: 45,
          child: CustomPaint(
            size: const Size(45, 45),
            painter: ActivityRingPainter(
              outerProgress: progress1,
              middleProgress: progress2,
              innerProgress: progress3,
              outerColor: color1,
              middleColor: color2,
              innerColor: color3,
              showGlow: true,
              customStrokeWidth: 3, // Biraz kalınlaştırıldı boşluk için
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer3<FoodProvider, ExerciseProvider, NativeStepCounterService>(
      builder: (context, foodProvider, exerciseProvider, stepService, child) {
        final bool isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
        
        final consumed = foodProvider.getDailyCalories(_selectedDate);
        final burned = exerciseProvider.getDailyBurnedCalories(_selectedDate);
        final steps = isToday ? stepService.dailySteps : 0; // Geçmiş günler için 0

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(context, 'Alınan', '${consumed.toInt()} kal', AppColors.calorieColor),
            _buildStatItem(context, 'Yakılan', '${burned.toInt()} kal', Colors.orange),
            _buildStatItem(context, 'Adım', '$steps', AppColors.stepColor),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}