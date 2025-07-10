// lib/screens/food_calories_screen.dart
import 'package:flutter/material.dart';
import 'package:formdakal/screens/food_search_screen.dart';
import 'package:provider/provider.dart';
import '../models/food_model.dart';
import '../providers/food_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';
import '../widgets/activity_calendar.dart';
import '../widgets/meal_card.dart';

class FoodCaloriesScreen extends StatefulWidget {
  const FoodCaloriesScreen({super.key});

  @override
  State<FoodCaloriesScreen> createState() => _FoodCaloriesScreenState();
}

class _FoodCaloriesScreenState extends State<FoodCaloriesScreen> with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  bool _isNutritionExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek & Makro Takibi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Calendar
              SliverToBoxAdapter(
                child: ActivityCalendar(
                  mode: CalendarMode.macros,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
              
              // Günlük Besin Kartı
              SliverToBoxAdapter(
                child: Consumer<FoodProvider>(
                  builder: (context, foodProvider, child) {
                    final allMeals = [
                      ...foodProvider.getMealFoods(_selectedDate, 'breakfast'),
                      ...foodProvider.getMealFoods(_selectedDate, 'lunch'),
                      ...foodProvider.getMealFoods(_selectedDate, 'dinner'),
                      ...foodProvider.getMealFoods(_selectedDate, 'snack'),
                    ];
                    
                    final totalCalories = allMeals.fold(0.0, (sum, food) => sum + food.totalCalories);
                    final totalProtein = allMeals.fold(0.0, (sum, food) => sum + food.totalProtein);
                    final totalCarbs = allMeals.fold(0.0, (sum, food) => sum + food.totalCarbs);
                    final totalFat = allMeals.fold(0.0, (sum, food) => sum + food.totalFat);
                    
                    return _buildNutritionCard(totalCalories, totalProtein, totalCarbs, totalFat);
                  },
                ),
              ),
              
              // Divider
              const SliverToBoxAdapter(
                child: Divider(height: 1),
              ),
              
              // Meals List
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMealSection(context, 'Kahvaltı', Icons.wb_sunny_outlined, 'breakfast'),
                    const SizedBox(height: 24),
                    _buildMealSection(context, 'Öğle Yemeği', Icons.fastfood_outlined, 'lunch'),
                    const SizedBox(height: 24),
                    _buildMealSection(context, 'Akşam Yemeği', Icons.dinner_dining_outlined, 'dinner'),
                    const SizedBox(height: 24),
                    _buildMealSection(context, 'Aperatifler/Diğer', Icons.icecream_outlined, 'snack'),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard(double calories, double protein, double carbs, double fat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isNutritionExpanded = !_isNutritionExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Günlük Besin Değerleri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      _isNutritionExpanded 
                          ? Icons.keyboard_arrow_up_rounded 
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Özet
                Row(
                  children: [
                    _buildStatItem('Kalori', calories.toInt().toString(), 'kcal', Colors.orange),
                    _buildStatItem('Protein', protein.toStringAsFixed(1), 'g', Colors.blue),
                    _buildStatItem('Karb', carbs.toStringAsFixed(1), 'g', Colors.green),
                    _buildStatItem('Yağ', fat.toStringAsFixed(1), 'g', Colors.red),
                  ],
                ),
                
                // Detaylar
                if (_isNutritionExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('Kalori', Icons.local_fire_department_rounded, calories, 'kcal', Colors.orange, isDark),
                  const SizedBox(height: 8),
                  _buildDetailRow('Protein', Icons.fitness_center_rounded, protein, 'g', Colors.blue, isDark),
                  const SizedBox(height: 8),
                  _buildDetailRow('Karbonhidrat', Icons.grass_rounded, carbs, 'g', Colors.green, isDark),
                  const SizedBox(height: 8),
                  _buildDetailRow('Yağ', Icons.opacity_rounded, fat, 'g', Colors.red, isDark),
                  const SizedBox(height: 8),
                  _buildDetailRow('Şeker', Icons.cake_rounded, carbs * 0.3, 'g', Colors.pink, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String name, IconData icon, double value, String unit, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(BuildContext context, String title, IconData icon, String mealType) {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final meals = foodProvider.getMealFoods(_selectedDate, mealType);
        return MealCard(
          title: title,
          icon: icon,
          totalCalories: meals.fold(0.0, (sum, food) => sum + food.totalCalories),
          totalProtein: meals.fold(0.0, (sum, food) => sum + food.totalProtein),
          totalCarbs: meals.fold(0.0, (sum, food) => sum + food.totalCarbs),
          totalFat: meals.fold(0.0, (sum, food) => sum + food.totalFat),
          foods: meals,
          onAddFood: () => _navigateToAddFood(context, mealType),
          onEditFood: (food) => _editConsumedFood(context, food),
          onDeleteFood: (foodId) => _deleteConsumedFood(context, foodId),
        );
      },
    );
  }

  void _navigateToAddFood(BuildContext context, String mealType) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FoodSearchScreen(mealType: mealType)));
  }

  void _editConsumedFood(BuildContext context, ConsumedFood food) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.foodName} düzenleme özelliği henüz eklenmedi.')),
    );
  }

  void _deleteConsumedFood(BuildContext context, String consumedFoodId) {
    Provider.of<FoodProvider>(context, listen: false)
        .removeConsumedFood(consumedFoodId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yemek kaydı silindi.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      await Provider.of<FoodProvider>(context, listen: false).loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yemek verileri güncellendi'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Güncelleme hatası'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}