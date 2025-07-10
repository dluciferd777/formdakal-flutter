// lib/widgets/advanced_step_counter_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/advanced_step_counter_service.dart';
import '../utils/colors.dart';

class AdvancedStepCounterCard extends StatefulWidget {
  const AdvancedStepCounterCard({super.key});

  @override
  State<AdvancedStepCounterCard> createState() => _AdvancedStepCounterCardState();
}

class _AdvancedStepCounterCardState extends State<AdvancedStepCounterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Servisi başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStepCounter();
    });
  }

  Future<void> _initializeStepCounter() async {
    final stepService = AdvancedStepCounterService();
    if (!stepService.isServiceActive) {
      await stepService.initialize();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: AdvancedStepCounterService(),
      child: Consumer<AdvancedStepCounterService>(
        builder: (context, stepService, child) {
          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  onTap: () => _showStepDetails(context, stepService),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryGreen.withOpacity(0.1),
                          AppColors.primaryGreen.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık ve Durum
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.directions_walk,
                                      color: AppColors.primaryGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Adım Sayar',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: stepService.isServiceActive
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            stepService.isServiceActive ? 'Aktif' : 'Başlatılıyor...',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Yürüme durumu
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: stepService.isWalking
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      stepService.isWalking ? Icons.directions_walk : Icons.pause,
                                      size: 16,
                                      color: stepService.isWalking ? Colors.green : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stepService.isWalking ? 'Yürüyor' : 'Durgun',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: stepService.isWalking ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Adım Sayısı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bugün',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      '${stepService.todaySteps}',
                                      key: ValueKey(stepService.todaySteps),
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'adım',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Hedef göstergesi
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Hedef: 10.000',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 120,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (stepService.todaySteps / 10000).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryGreen,
                                              AppColors.primaryGreen.withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${((stepService.todaySteps / 10000) * 100).toInt()}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Hızlı Aksiyonlar
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  'Sıfırla',
                                  Icons.refresh,
                                  () => _showResetDialog(context, stepService),
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  'Test Adım',
                                  Icons.add,
                                  () => stepService.addTestStep(),
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  void _showStepDetails(BuildContext context, AdvancedStepCounterService stepService) {
    Navigator.pushNamed(context, '/step_details');
  }

  void _showResetDialog(BuildContext context, AdvancedStepCounterService stepService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adımları Sıfırla'),
        content: const Text('Bugünkü adım sayısını sıfırlamak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              stepService.resetDailySteps();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Günlük adımlar sıfırlandı'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}