// lib/widgets/activity_calendar.dart - ESKİ HALİ RESTORE EDİLDİ
import 'package:flutter/material.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/food_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:formdakal/widgets/activity_ring_painter.dart';
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
    // Haftanın başlangıcını Pazartesi olarak ayarla (weekday: 1)
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weeks * 7));
      _selectedDate = _currentWeekStart; // Haftayı değiştirince seçili tarihi de ilk güne ayarla
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
          const SizedBox(height: 8), // Boşluk azaltıldı
          // Takvimi yatay kaydırılabilir hale getirmek için SingleChildScrollView eklendi
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
          padding: const EdgeInsets.only(left: 16.0), // Sol padding eklendi
          child: Text(
            // Tarih formatı "2025 Temmuz Pazartesi" şeklinde ayarlandı ve boyutu küçültüldü
            DateFormat('yyyy MMMM EEEE', 'tr_TR').format(_currentWeekStart),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16), // Boyut küçültüldü
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeWeek(-1),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeWeek(1),
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
          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Günler arası boşluk eklendi
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
            DateFormat('E', 'tr_TR').format(date).substring(0, 1), // Haftanın günü kısaltması
            style: theme.textTheme.bodySmall
                ?.copyWith(color: isToday ? AppColors.primaryGreen : null),
          ),
          const SizedBox(height: 6), // Boşluk azaltıldı
          _buildActivityRingForDay(date, isSelected),
          const SizedBox(height: 6), // Boşluk azaltıldı
          Container(
            height: 22, // Boyut küçültüldü
            width: 22, // Boyut küçültüldü
            decoration: isSelected
                ? const BoxDecoration(
                    color: AppColors.primaryGreen, shape: BoxShape.circle)
                : null,
            child: Center(
              child: Text(
                date.day.toString(),
                style: theme.textTheme.bodySmall?.copyWith( // Yazı boyutu küçültüldü
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
    return Consumer3<UserProvider, FoodProvider, ExerciseProvider>(
      builder: (context, userProvider, foodProvider, exerciseProvider, child) {
        double progress1 = 0, progress2 = 0, progress3 = 0;
        Color color1 = Colors.grey, color2 = Colors.grey, color3 = Colors.grey;

        final user = userProvider.user;

        if (widget.mode == CalendarMode.activity) {
          // Adım, Yemek Kalori (Alınan), Yakılan Kalori (Fitness Kalori)
          final steps = exerciseProvider.dailySteps;
          final intakeCalories = foodProvider.getDailyCalories(date);
          final burnedCalories = exerciseProvider.getDailyBurnedCalories(date);

          // Hedefler kullanıcıdan veya varsayılan değerlerden alınır
          final stepGoal = user?.dailyStepGoal ?? 6000;
          final calorieIntakeGoal = user?.dailyCalorieNeeds ?? 2000;
          final calorieBurnGoal = (user?.dailyCalorieNeeds ?? 2000) * 0.25; 

          progress1 = (steps / stepGoal).clamp(0.0, 1.0);
          progress2 = (intakeCalories / calorieIntakeGoal).clamp(0.0, 1.0);
          progress3 = (burnedCalories / calorieBurnGoal).clamp(0.0, 1.0);

          color1 = AppColors.stepColor;       // Adım için yeşil
          color2 = AppColors.calorieColor;    // Alınan kalori için pembe
          color3 = AppColors.primaryGreen;    // Yakılan kalori için ana yeşil
        } else if (widget.mode == CalendarMode.macros) {
          // Protein, Karbonhidrat, Yağ - NULL CHECK KALDIRILDI
          final protein = foodProvider.getDailyProtein(date);
          final carbs = foodProvider.getDailyCarbs(date);
          final fat = foodProvider.getDailyFat(date);

          // Hedefler - user null olsa bile varsayılan değerler kullanılır
          final proteinGoal = user?.dailyProteinGoal ?? 100.0; // Varsayılan 100g
          final carbGoal = user?.dailyCarbGoal ?? 200.0; // Varsayılan 200g
          final fatGoal = user?.dailyFatGoal ?? 50.0; // Varsayılan 50g

          progress1 = (protein / proteinGoal).clamp(0.0, 1.0);
          progress2 = (carbs / carbGoal).clamp(0.0, 1.0);
          progress3 = (fat / fatGoal).clamp(0.0, 1.0);

          // Renkler her zaman ayarlanır - user null olsa bile
          color1 = AppColors.primaryGreen; // Protein için ana yeşil
          color2 = Colors.orange;          // Karbonhidrat için turuncu
          color3 = AppColors.error;        // Yağ için kırmızı
        }

        // Halka boyutu korundu
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
              showGlow: true, // Yemek verileri girildiğinde parlasın!
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer2<FoodProvider, ExerciseProvider>(
      builder: (context, foodProvider, exerciseProvider, child) {
        final consumed = foodProvider.getDailyCalories(_selectedDate);
        final burned = exerciseProvider.getDailyBurnedCalories(_selectedDate);
        final minutes = exerciseProvider.getDailyExerciseMinutes(_selectedDate);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(context, 'Alınan', '${consumed.toInt()} kal', AppColors.calorieColor),
            _buildStatItem(context, 'Yakılan', '${burned.toInt()} kal', AppColors.primaryGreen),
            _buildStatItem(context, 'Egzersiz', '${minutes} dk', AppColors.timeColor),
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