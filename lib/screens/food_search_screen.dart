// lib/screens/food_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_model.dart';
import '../providers/food_provider.dart';
import '../utils/colors.dart';
// Tüm yemek veri dosyalarını import ediyoruz
import '../data/food_data_turkish.dart';
import '../data/food_data_desserts_snacks.dart';
import '../data/food_data_international.dart';
import '../data/food_data_main_dishes.dart';
import '../data/food_data_main_dishes_part2.dart'; // Yeni eklendi
import '../data/food_data_main_dishes_part3.dart'; // Yeni eklendi
import '../data/food_data_main_dishes_part4.dart'; // Yeni eklendi
import '../data/food_data_sports_foods.dart'; // Yeni eklendi
import '../data/food_data_fast_food.dart'; // Yeni eklendi


class FoodSearchScreen extends StatefulWidget {
  final String mealType;
  const FoodSearchScreen({super.key, required this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Tüm yemek listelerini burada birleştiriyoruz
  late final List<FoodModel> _allFoods;

  @override
  void initState() {
    super.initState();
    // Tüm listeleri tek bir listede birleştir
    _allFoods = [
      ...turkishFoods,
      ...dessertsAndSnacks,
      ...internationalFoods,
      ...mainDishes,
      ...mainDishesPart2,
      ...mainDishesPart3,
      ...mainDishesPart4,
      ...sportsFoods,
      ...fastFoodItems,
      // Gelecekte eklenecek diğer listeler buraya eklenebilir
    ];

    _searchController.addListener(_onSearchChanged);
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch(_searchController.text);
  }

  void _performSearch(String query) {
    setState(() {
      _isLoading = false;
      _errorMessage = null;

      if (query.isEmpty) {
        // Arama kutusu boşken son arama geçmişini göster
        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
        final recentSearches = foodProvider.searchHistory;
        _searchResults = _allFoods.where((food) =>
            recentSearches.any((searchQuery) => food.name.toLowerCase().contains(searchQuery.toLowerCase()))
        ).toList();
        // Eğer arama geçmişinde eşleşen yoksa veya arama geçmişi boşsa, ilk 10 yemeği göster
        if (_searchResults.isEmpty && recentSearches.isEmpty) {
          _searchResults = _allFoods.take(10).toList(); // İlk 10 yemeği varsayılan olarak göster
        }
        return;
      }

      final lowerCaseQuery = query.toLowerCase().trim();
      _searchResults = _allFoods.where((food) {
        return food.name.toLowerCase().contains(lowerCaseQuery);
      }).toList();

      if (_searchResults.isEmpty) {
        _errorMessage = 'Aradığınız yiyecek bulunamadı.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yiyecek Ara'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Yiyecek ara...',
                  hintText: 'Örn: Tavuk Göğsü, Elma',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _searchResults.isEmpty && _searchController.text.isNotEmpty
                          ? const Center(child: Text('Sonuç bulunamadı.'))
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final food = _searchResults[index];
                                return ListTile(
                                  title: Text(food.name),
                                  subtitle:
                                      Text('${food.calories.toInt()} kal / 100g'),
                                  trailing: const Icon(Icons.add),
                                  onTap: () {
                                    Provider.of<FoodProvider>(context, listen: false)
                                        .addToSearchHistory(food.name);
                                    _showFoodDetailsDialog(context, food);
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetailsDialog(BuildContext context, FoodModel food) {
    final TextEditingController gramsController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            double currentGrams = double.tryParse(gramsController.text) ?? 100.0;

            double calculatedCalories = food.getCaloriesForGrams(currentGrams);
            double calculatedProtein = food.getProteinForGrams(currentGrams);
            double calculatedCarbs = food.getCarbsForGrams(currentGrams);
            double calculatedFat = food.getFatForGrams(currentGrams);
            double calculatedSugar = food.getSugarForGrams(currentGrams);
            double calculatedFiber = food.getFiberForGrams(currentGrams);
            double calculatedSodium = food.getSodiumForGrams(currentGrams);


            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16, left: 16, right: 16
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(food.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
                    ),
                    const Divider(height: 20),
                    TextField(
                      controller: gramsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Miktar (gram)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionRow('Kalori', '${calculatedCalories.toInt()} kcal', AppColors.calorieColor),
                    _buildNutritionRow('Protein', '${calculatedProtein.toStringAsFixed(1)} g', AppColors.primaryGreen),
                    _buildNutritionRow('Yağ', '${calculatedFat.toStringAsFixed(1)} g', Colors.redAccent),
                    _buildNutritionRow('Karbonhidrat', '${calculatedCarbs.toStringAsFixed(1)} g', Colors.orange),
                    if (food.sugar != null) _buildNutritionRow('Şeker', '${calculatedSugar.toStringAsFixed(1)} g', Colors.purple),
                    if (food.fiber != null) _buildNutritionRow('Lif', '${calculatedFiber.toStringAsFixed(1)} g', Colors.brown),
                    if (food.sodium != null) _buildNutritionRow('Sodyum', '${calculatedSodium.toInt()} mg', Colors.blueGrey),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final consumedFood = ConsumedFood(
                          foodId: food.id,
                          foodName: food.name,
                          grams: currentGrams,
                          totalCalories: calculatedCalories,
                          totalProtein: calculatedProtein,
                          totalCarbs: calculatedCarbs,
                          totalFat: calculatedFat,
                          mealType: widget.mealType,
                          consumedAt: DateTime.now(),
                          totalSugar: calculatedSugar,
                          totalFiber: calculatedFiber,
                          totalSodium: calculatedSodium,
                        );
                        Provider.of<FoodProvider>(context, listen: false)
                            .addConsumedFood(consumedFood);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Öğüne Ekle', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
