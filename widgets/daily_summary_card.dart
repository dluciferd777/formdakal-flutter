// lib/widgets/daily_summary_card.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../providers/exercise_provider.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../utils/colors.dart';

class DailySummaryCard extends StatelessWidget {
  final GlobalKey? shareKey;
  
  const DailySummaryCard({super.key, this.shareKey});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: shareKey,
      child: Consumer3<FoodProvider, ExerciseProvider, UserProvider>(
        builder: (context, foodProvider, exerciseProvider, userProvider, child) {
          final user = userProvider.user;
          final consumedCalories = foodProvider.getDailyCalories(DateTime.now());
          final burnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
          final targetCalories = user?.dailyCalorieNeeds ?? 2000;
          final remainingCalories = targetCalories - consumedCalories + burnedCalories;
          final netCalories = consumedCalories - burnedCalories;
          
          final bmr = user?.bmr.toInt() ?? 1500;
          final tdee = targetCalories.toInt();

          return Container(
            width: 380,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E), // iOS Dark mode arka plan
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Tarih ve Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: 'F',
                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 24),
                          ),
                          TextSpan(text: 'ormda', style: TextStyle(color: Colors.white)),
                          TextSpan(
                            text: 'K',
                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 24),
                          ),
                          TextSpan(text: 'al', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy', 'tr_TR').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Fitness Kalori Kartı
                _buildSectionCard(
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primaryGreen,
                  title: 'Fitness Kalori',
                  subtitle: 'Bugün yakılan kalori',
                  value: burnedCalories.toInt().toString(),
                  unit: 'kal',
                  bottomText: 'Bugün henüz egzersiz yapmadınız.',
                ),
                const SizedBox(height: 12),
                
                // Yemek Kalori Kartı
                _buildSectionCard(
                  icon: Icons.restaurant,
                  iconColor: AppColors.calorieColor,
                  title: 'Yemek Kalori',
                  subtitle: 'Bugün alınan kalori',
                  value: consumedCalories.toInt().toString(),
                  unit: 'kal',
                  bottomText: 'Bugün henüz yemek eklemediniz.',
                ),
                const SizedBox(height: 12),
                
                // Kalori Takip Kartı
                _buildSectionCard(
                  icon: Icons.track_changes,
                  iconColor: Colors.blueAccent,
                  title: 'Kalori Takip',
                  subtitle: 'Net kalori dengesi',
                  value: netCalories.toInt().toString(),
                  unit: 'kal',
                  bottomText: null,
                ),
                const SizedBox(height: 20),
                
                // Alınan/Yakılan Özet Kartları
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.calorieColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Alınan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              consumedCalories.toInt().toString(),
                              style: const TextStyle(
                                color: AppColors.calorieColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'kal',
                              style: TextStyle(
                                color: AppColors.calorieColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Yakılan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              burnedCalories.toInt().toString(),
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'kal',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Günlük Kalori Özeti
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Günlük Kalori Özeti',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCalorieItem('Hedef', targetCalories.toInt(), AppColors.primaryGreen),
                          _buildCalorieItem('Alınan', consumedCalories.toInt(), AppColors.calorieColor),
                          _buildCalorieItem('Yakılan', burnedCalories.toInt(), AppColors.primaryGreen),
                          _buildCalorieItem('Kalan', remainingCalories.toInt(), Colors.blueAccent),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BMR: $bmr kal | TDEE: $tdee kal',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    String? bottomText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white30,
                size: 16,
              ),
            ],
          ),
          if (bottomText != null) ...[
            const SizedBox(height: 12),
            Text(
              bottomText,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalorieItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value kal',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Basit Paylaşım Yöneticisi - path_provider olmadan
class SocialShareManager {
  static Future<void> shareDailySummary({
    required GlobalKey cardKey,
    required BuildContext context,
  }) async {
    try {
      // RepaintBoundary'nin render nesnesini al
      RenderRepaintBoundary? boundary = 
          cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paylaşılacak içerik bulunamadı.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Resmi yakala
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resim verisi oluşturulamadı.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Resmi doğrudan paylaş (dosya kaydetmeden)
      if (context.mounted) {
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await Share.shareXFiles(
          [XFile.fromData(
            byteData.buffer.asUint8List(),
            name: 'formdakal_gunluk_ozet_$dateStr.png',
            mimeType: 'image/png',
          )],
          subject: "FormdaKal - Günlük Aktivite Özetim",
          text: "Bugünkü aktivite özetim FormdaKal ile! 💪\n\n#FormdaKal #Fitness #Sağlık",
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}