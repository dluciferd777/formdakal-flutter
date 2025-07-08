// lib/widgets/meal_card.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/food_model.dart';

class MealCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final List<ConsumedFood> foods;
  final VoidCallback onAddFood;
  // HATA DÜZELTME: Fonksiyon imzaları, artık index yerine doğrudan nesne veya ID alacak şekilde güncellendi.
  // Bu, listedeki değişikliklerden etkilenmeyen daha güvenilir bir yapı sağlar.
  final Function(ConsumedFood food) onEditFood;
  final Function(String consumedFoodId) onDeleteFood;

  const MealCard({
    super.key,
    required this.title,
    required this.icon,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.foods,
    required this.onAddFood,
    required this.onEditFood,
    required this.onDeleteFood,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final fatColor = AppColors.error;
    final carbColor = Colors.amber.shade700;
    final proteinColor = AppColors.primaryGreen;

    double totalMacros = widget.totalCarbs + widget.totalFat + widget.totalProtein;
    double fatRatio = totalMacros > 0 ? widget.totalFat / totalMacros : 0;
    double carbsRatio = totalMacros > 0 ? widget.totalCarbs / totalMacros : 0;
    double proteinRatio = totalMacros > 0 ? widget.totalProtein / totalMacros : 0;

    return Card(
      elevation: isDarkMode ? 4 : 2,
      shadowColor: isDarkMode
          ? Colors.black.withOpacity(0.5)
          : Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Köşe yuvarlaklığı azaltıldı
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            child: InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6), // Padding azaltıldı
                child: Row(
                  children: [
                    Icon(widget.icon, color: proteinColor, size: 24), // İkon boyutu küçültüldü
                    const SizedBox(width: 10), // Boşluk azaltıldı
                    Text(widget.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)), // Yazı boyutu küçültüldü
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(widget.totalCalories.toInt().toString(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.calorieColor,
                                fontWeight: FontWeight.bold, fontSize: 22)), // Yazı boyutu küçültüldü
                        const Text("Kalori",
                            style: TextStyle(color: Colors.grey, fontSize: 10)), // Yazı boyutu küçültüldü
                      ],
                    ),
                    const SizedBox(width: 6), // Boşluk azaltıldı
                    IconButton(
                      icon: Icon(Icons.add_circle,
                          color: proteinColor, size: 24), // İkon boyutu küçültüldü
                      onPressed: widget.onAddFood,
                      tooltip: 'Yemek Ekle',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8), // Padding azaltıldı
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroInfo('Yağ', widget.totalFat, fatColor, isDarkMode),
                    _buildMacroInfo('Karb', widget.totalCarbs, carbColor, isDarkMode),
                    _buildMacroInfo('Prot', widget.totalProtein, proteinColor, isDarkMode),
                  ],
                ),
                const SizedBox(height: 6), // Boşluk azaltıldı
                Stack(
                  children: [
                    Container(
                        height: 4, // Yükseklik azaltıldı
                        decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4))), // Köşe yuvarlaklığı azaltıldı
                    LayoutBuilder(
                      builder: (context, constraints) => Row(
                        children: [
                          Container(
                              width: constraints.maxWidth * fatRatio,
                              height: 4, // Yükseklik azaltıldı
                              decoration: BoxDecoration(
                                  color: fatColor,
                                  borderRadius: BorderRadius.circular(4))), // Köşe yuvarlaklığı azaltıldı
                          Container(
                              width: constraints.maxWidth * carbsRatio,
                              height: 4, // Yükseklik azaltıldı
                              color: carbColor),
                          Container(
                              width: constraints.maxWidth * proteinRatio,
                              height: 4, // Yükseklik azaltıldı
                              decoration: BoxDecoration(
                                  color: proteinColor,
                                  borderRadius: BorderRadius.circular(4))), // Köşe yuvarlaklığı azaltıldı
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.shade50,
              child: Column(
                children: [
                  const Divider(height: 1, indent: 12, endIndent: 12), // Divider indent/endIndent azaltıldı
                  if (widget.foods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0), // Padding azaltıldı
                      child: Center(
                          child: Text('Bu öğüne henüz yemek eklenmedi.', style: TextStyle(fontSize: 12))), // Yazı boyutu küçültüldü
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 6.0), // Padding azaltıldı
                      child: Column(
                        children: widget.foods.map((food) {
                          return ListTile(
                            dense: true,
                            title: Text(food.foodName, style: const TextStyle(fontSize: 14)), // Yazı boyutu küçültüldü
                            subtitle: Text(
                                '${food.grams.toInt()} g | P: ${food.totalProtein.toInt()}g, K: ${food.totalCarbs.toInt()}g, Y: ${food.totalFat.toInt()}g',
                                style: const TextStyle(fontSize: 11)), // Yazı boyutu küçültüldü
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: AppColors.error), // İkon boyutu küçültüldü
                              onPressed: () => widget.onDeleteFood(food.id),
                            ),
                            onTap: () => widget.onEditFood(food),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, double value, Color color, bool isDarkMode) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12), // Yazı boyutu küçültüldü
        ),
        const SizedBox(height: 2), // Boşluk azaltıldı
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14, // Yazı boyutu küçültüldü
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
