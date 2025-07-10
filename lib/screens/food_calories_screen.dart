// lib/screens/food_calories_screen.dart - DÜZELTİLMİŞ
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
          // Tema tuşunu ana sayfadaki gibi dikdörtgen kaplama ile sarıyoruz
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GestureDetector(
              onTap: () => context.read<ThemeProvider>().toggleTheme(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  context.watch<ThemeProvider>().isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white, // AppBar beyaz olduğu için ikon beyaz
                ),
              ),
            ),
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