// lib/widgets/advanced_step_counter_card.dart - GERÇEK WİDGET
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/advanced_step_counter_service.dart';
import '../utils/colors.dart';

class AdvancedStepCounterCard extends StatefulWidget {
  const AdvancedStepCounterCard({super.key});

  @override
  State<AdvancedStepCounterCard> createState() => _AdvancedStepCounterCardState();
}

class _AdvancedStepCounterCardState extends State<AdvancedStepCounterCard> {
  late AdvancedStepCounterService _stepService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeStepCounter();
  }

  Future<void> _initializeStepCounter() async {
    try {
      _stepService = AdvancedStepCounterService();
      await _stepService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Adım sayar başlatma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingCard();
    }

    return ChangeNotifierProvider.value(
      value: _stepService,
      child: Consumer<AdvancedStepCounterService>(
        builder: (context, stepService, child) {
          final todaySteps = stepService.todaySteps;
          final isWalking = stepService.isWalking;
          final isActive = stepService.isServiceActive;
          final progress = (todaySteps / 10000).clamp(0.0, 1.0);
          final calories = stepService.getCaloriesFromSteps();
          final distance = stepService.getDistanceFromSteps();

          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.1),
                    AppColors.primaryGreen.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isWalking 
                              ? AppColors.primaryGreen.withOpacity(0.3)
                              : AppColors.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isWalking ? Icons.directions_walk : Icons.directions_walk_outlined,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Adım Sayacı',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isActive)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isWalking ? AppColors.primaryGreen : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              isWalking ? 'Yürüyorsunuz' : 'Aktif değil',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isWalking ? AppColors.primaryGreen : Colors.grey.shade600,
                                fontWeight: isWalking ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            todaySteps.toString(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Text(
                            'adım',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Günlük Hedef',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? AppColors.success : AppColors.primaryGreen,
                        ),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$todaySteps / 10,000',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (todaySteps >= 10000)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Hedef Tamamlandı! 🎉',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Kalori',
                          '${calories}',
                          'kal',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Mesafe',
                          '${distance.toStringAsFixed(2)}',
                          'km',
                          Icons.straighten,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _stepService.resetDailySteps();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Günlük adımlar sıfırlandı'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Sıfırla', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _stepService.addTestStep();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test adımı eklendi'),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Test', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
              SizedBox(height: 12),
              Text('Adım sayar başlatılıyor...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}