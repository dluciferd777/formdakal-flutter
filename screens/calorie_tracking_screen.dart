// lib/screens/calorie_tracking_screen.dart - DÜZELTİLMİŞ
import 'package:flutter/material.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/food_provider.dart';
import 'package:formdakal/providers/theme_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/services/calorie_service.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:provider/provider.dart';

class CalorieTrackingScreen extends StatelessWidget {
  const CalorieTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      // DÜZELTİLMİŞ APPBAR - Tema uyumlu
      appBar: AppBar(
        title: const Text('Kalori & Makro Raporu'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: isDarkMode ? 0 : 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeProvider>().isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer3<UserProvider, FoodProvider, ExerciseProvider>(
          builder: (context, userProvider, foodProvider, exerciseProvider, child) {
            final user = userProvider.user;

            if (user == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Raporları görüntülemek için lütfen önce profil bilgilerinizi giriniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              );
            }

            final dailyCalorieTarget = user.dailyCalorieNeeds;
            final consumedCalories = foodProvider.getDailyCalories(DateTime.now());
            final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
            final remainingCalories = dailyCalorieTarget - consumedCalories + burnedCalories;
            final bmr = user.bmr.toInt();
            final tdee = CalorieService.calculateTDEE(gender: user.gender, weight: user.weight, height: user.height, age: user.age, activityLevel: user.activityLevel).toInt();
            final dailyWaterTarget = CalorieService.calculateDailyWaterNeeds(weight: user.weight, activityLevel: user.activityLevel);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Bazal Metabolizma Hızı (BMR) Kartı - EN ÜSTTE
                  _buildMetabolismCard(context, bmr, tdee),
                  const SizedBox(height: 16),

                  // 2. Kalori Dengesi Kartı
                  _buildCalorieBalanceCard(context, consumedCalories, burnedCalories, remainingCalories),
                  const SizedBox(height: 16),

                  // 3. Makro Besin Dağılımı Kartı
                  _buildMacroDistributionCard(context, foodProvider, user),
                  const SizedBox(height: 16),

                  // 4. Su İhtiyacı Kartı
                  _buildWaterNeedsCard(context, dailyWaterTarget),
                  const SizedBox(height: 16),

                  // 5. Kilo Hedefi Kartı
                  _buildWeightGoalCard(context, userProvider),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 1. Bazal Metabolizma Hızı (BMR) Kartı - EN ÜST SIRAYA TAŞINDI
  Widget _buildMetabolismCard(BuildContext context, int bmr, int tdee) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.timeColor, size: 24),
                const SizedBox(width: 8),
                Text('Bazal Metabolizma Hızı (BMR)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$bmr kal / gün',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.timeColor, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              '%100 dinlenme halinde gereken günlük kalori miktarı. Hiçbir zaman bu miktarın altında beslenmemelisiniz. Bu hızlı kilo yağ yakmaz, hali hazırda ki.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text('Böyle Devam! Dozu (TDEE)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$tdee kal / gün',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'Günlük toplam kalori ihtiyacınız. Ortalamada bu miktarda kalori alırsanız, bu aktivite değişmediği sürece vücut ağırlığınız sabit kalacaktır. Ancak toplam kütle sabit olsa da, ağırlık çalışmazsanız kas kaybedip yağ kaybedebilirsiniz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Kalori Dengesi Kartı
  Widget _buildCalorieBalanceCard(BuildContext context, double consumed, double burned, double remaining) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final netCalories = consumed - burned;
    final isDeficit = netCalories < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text('Kalori Dengesi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Text(
                '${netCalories.toInt()}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isDeficit ? AppColors.primaryGreen : AppColors.calorieColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'kal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDeficit ? AppColors.primaryGreen : AppColors.calorieColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDeficit ? 'Bugünkü kalori açığı' : 'Bugünkü kalori fazlası',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            Text(
              'Alınan: ${consumed.toInt()} kal - Yakılan: ${burned.toInt()} kal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),
            Text('Günlük Kalori Özeti', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isDarkMode ? Colors.white : Colors.black, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCalorieStatItem(context, 'Hedef', remaining + consumed - burned, AppColors.primaryGreen),
                _buildCalorieStatItem(context, 'Alınan', consumed, AppColors.calorieColor),
                _buildCalorieStatItem(context, 'Yakılan', burned, AppColors.primaryGreen),
                _buildCalorieStatItem(context, 'Kalan', remaining, Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 8),
            Text('BMR: ${consumed.toInt()} kal | TDEE: ${burned.toInt()} kal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDarkMode ? Colors.white70 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  // 3. Makro Besin Dağılımı Kartı
  Widget _buildMacroDistributionCard(BuildContext context, FoodProvider foodProvider, user) {
    final protein = foodProvider.getDailyProtein(DateTime.now());
    final carbs = foodProvider.getDailyCarbs(DateTime.now());
    final fat = foodProvider.getDailyFat(DateTime.now());
    final sugar = foodProvider.getDailySugar(DateTime.now());
    final fiber = foodProvider.getDailyFiber(DateTime.now());
    final sodium = foodProvider.getDailySodium(DateTime.now());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text('Makro Besin Dağılımı', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMacroRow(context, 'Protein', '${protein.toInt()} g', AppColors.primaryGreen),
            _buildMacroRow(context, 'Yağ', '${fat.toInt()} g', AppColors.error),
            _buildMacroRow(context, 'Karbonhidrat', '${carbs.toInt()} g', Colors.orange),
            if (sugar > 0) _buildMacroRow(context, 'Şeker', '${sugar.toInt()} g', Colors.purple),
            if (fiber > 0) _buildMacroRow(context, 'Lif', '${fiber.toInt()} g', Colors.brown),
            if (sodium > 0) _buildMacroRow(context, 'Sodyum', '${sodium.toInt()} mg', Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  // 4. Su İhtiyacı Kartı
  Widget _buildWaterNeedsCard(BuildContext context, double dailyWaterTarget) {
    final userProvider = Provider.of<UserProvider>(context);
    final dailyWaterIntake = userProvider.getDailyWaterIntake(DateTime.now());
    final remainingWater = (dailyWaterTarget - dailyWaterIntake).clamp(0.0, dailyWaterTarget);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: AppColors.timeColor, size: 24),
                const SizedBox(width: 8),
                Text('Su İhtiyacı', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${dailyWaterIntake.toStringAsFixed(2)} litre / gün',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.timeColor, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeterli hidrasyon, metabolizma ve genel sağlık için kritik öneme sahiptir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Hedef: ${dailyWaterTarget.toStringAsFixed(2)} litre | Kalan: ${remainingWater.toStringAsFixed(2)} litre',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Kilo Hedefi Kartı
  Widget _buildWeightGoalCard(BuildContext context, UserProvider userProvider) {
    final user = userProvider.user!;
    final idealWeightRange = CalorieService.getIdealWeightRange(user.height);
    final bmiCategory = userProvider.getBMICategory();
    final isObese = bmiCategory == 'Obez';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text('Kilo Hedefi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMacroRow(context, 'Mevcut Kilonuz', '${user.weight.toInt()} kg', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
            _buildMacroRow(context, 'İdeal Kilo Aralığı', '${idealWeightRange['min']!.toInt()} - ${idealWeightRange['max']!.toInt()} kg', Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
            if (isObese) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obezite sınıfındasınız. Sağlığınız için kilo vermeniz önerilir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text('BMI: ${user.bmi.toStringAsFixed(1)} (${user.gender == 'male' ? 'Erkek' : 'Kadın'})', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Yardımcı widget'lar
  Widget _buildCalorieStatItem(BuildContext context, String title, double value, Color color) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 4),
        Text('${value.toInt()} kal', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildMacroRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}