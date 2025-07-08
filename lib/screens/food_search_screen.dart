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
import '../data/food_data_main_dishes_part2.dart';
import '../data/food_data_main_dishes_part3.dart';
import '../data/food_data_main_dishes_part4.dart';
import '../data/food_data_sports_foods.dart';
import '../data/food_data_fast_food.dart';

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

  late final List<FoodModel> _allFoods;

  @override
  void initState() {
    super.initState();
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
        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
        final recentSearches = foodProvider.searchHistory;
        _searchResults = _allFoods.where((food) =>
            recentSearches.any((searchQuery) => food.name.toLowerCase().contains(searchQuery.toLowerCase()))
        ).take(15).toList();
        if (_searchResults.isEmpty) {
          _searchResults = _allFoods.take(15).toList();
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
                                  trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FoodDetailsSheet(food: food, mealType: widget.mealType),
    );
  }
}


// YENİ: Ayrı bir Stateful Widget olarak yeniden düzenlendi
class FoodDetailsSheet extends StatefulWidget {
  final FoodModel food;
  final String mealType;

  const FoodDetailsSheet({super.key, required this.food, required this.mealType});

  @override
  State<FoodDetailsSheet> createState() => _FoodDetailsSheetState();
}

class _FoodDetailsSheetState extends State<FoodDetailsSheet> {
  late String _selectedUnit;
  final TextEditingController _amountController = TextEditingController();
  
  // Besin değerlerini tutacak state değişkenleri
  double _calculatedCalories = 0;
  double _calculatedProtein = 0;
  double _calculatedCarbs = 0;
  double _calculatedFat = 0;
  double _calculatedSugar = 0;
  double _calculatedFiber = 0;
  double _calculatedSodium = 0;
  double _totalGrams = 0;

  @override
  void initState() {
    super.initState();
    
    // Yiyeceğin porsiyon tanımı var mı kontrol et
    if (widget.food.servingUnitName != null && widget.food.servingSizeGrams != null) {
      _selectedUnit = widget.food.servingUnitName!;
      _amountController.text = '1'; // Varsayılan 1 porsiyon
    } else {
      _selectedUnit = 'gram';
      _amountController.text = '100'; // Varsayılan 100 gram
    }
    
    _calculateNutrition(); // Başlangıç değerlerini hesapla
    _amountController.addListener(_calculateNutrition);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateNutrition() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    
    if (_selectedUnit == 'gram') {
      _totalGrams = amount;
    } else {
      _totalGrams = amount * (widget.food.servingSizeGrams ?? 1.0);
    }

    setState(() {
      _calculatedCalories = widget.food.getCaloriesForGrams(_totalGrams);
      _calculatedProtein = widget.food.getProteinForGrams(_totalGrams);
      _calculatedCarbs = widget.food.getCarbsForGrams(_totalGrams);
      _calculatedFat = widget.food.getFatForGrams(_totalGrams);
      _calculatedSugar = widget.food.getSugarForGrams(_totalGrams);
      _calculatedFiber = widget.food.getFiberForGrams(_totalGrams);
      _calculatedSodium = widget.food.getSodiumForGrams(_totalGrams);
    });
  }

  void _addFoodToMeal() {
    final consumedFood = ConsumedFood(
      foodId: widget.food.id,
      foodName: widget.food.name,
      grams: _totalGrams,
      totalCalories: _calculatedCalories,
      totalProtein: _calculatedProtein,
      totalCarbs: _calculatedCarbs,
      totalFat: _calculatedFat,
      mealType: widget.mealType,
      consumedAt: DateTime.now(),
      totalSugar: _calculatedSugar,
      totalFiber: _calculatedFiber,
      totalSodium: _calculatedSodium,
    );
    Provider.of<FoodProvider>(context, listen: false).addConsumedFood(consumedFood);
    Navigator.pop(context); // Bottom sheet'i kapat
    Navigator.pop(context); // Arama ekranını kapat
  }

  @override
  Widget build(BuildContext context) {
    // Porsiyon seçeneği olup olmadığını kontrol et
    bool hasServingUnit = widget.food.servingUnitName != null && widget.food.servingSizeGrams != null;

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
              child: Text(widget.food.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
            ),
            const Divider(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                if (hasServingUnit)
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(value: 'gram', label: const Text('gram')),
                      ButtonSegment<String>(value: widget.food.servingUnitName!, label: Text(widget.food.servingUnitName!)),
                    ],
                    selected: {_selectedUnit},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedUnit = newSelection.first;
                        // Birim değiştiğinde miktarı sıfırla veya ayarla
                        if (_selectedUnit == 'gram') {
                          _amountController.text = '100';
                        } else {
                          _amountController.text = '1';
                        }
                        _calculateNutrition();
                      });
                    },
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            _buildNutritionRow('Kalori', '${_calculatedCalories.toInt()} kcal', AppColors.calorieColor),
            _buildNutritionRow('Protein', '${_calculatedProtein.toStringAsFixed(1)} g', AppColors.primaryGreen),
            _buildNutritionRow('Yağ', '${_calculatedFat.toStringAsFixed(1)} g', Colors.redAccent),
            _buildNutritionRow('Karbonhidrat', '${_calculatedCarbs.toStringAsFixed(1)} g', Colors.orange),
            if (widget.food.sugar != null) _buildNutritionRow('Şeker', '${_calculatedSugar.toStringAsFixed(1)} g', Colors.purple),
            if (widget.food.fiber != null) _buildNutritionRow('Lif', '${_calculatedFiber.toStringAsFixed(1)} g', Colors.brown),
            if (widget.food.sodium != null) _buildNutritionRow('Sodyum', '${_calculatedSodium.toInt()} mg', Colors.blueGrey),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _addFoodToMeal,
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
