// lib/widgets/custom_drawer.dart - PROFİL BİLGİLERİ ALTTA
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/exercise_provider.dart';
import '../utils/colors.dart';
import 'activity_ring_painter.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: AppColors.primaryGreen.withOpacity(0.2),
      end: AppColors.primaryGreen.withOpacity(0.5),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  ImageProvider? _buildProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    if (kIsWeb) {
      return NetworkImage(imagePath);
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 280, // Drawer genişliği artırıldı
      child: Drawer(
        child: Column(
          children: [
            Consumer2<UserProvider, ExerciseProvider>(
              builder: (context, userProvider, exerciseProvider, child) {
                final user = userProvider.user;
                final imageProvider = _buildProfileImage(user?.profileImagePath);
                
                final double dailyBurnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
                final double calorieGoal = user?.dailyCalorieNeeds != null ? user!.dailyCalorieNeeds * 0.25 : 500;
                final double progress = (dailyBurnedCalories / calorieGoal).clamp(0.0, 1.0);

                return Container(
                  height: 180, // Header yüksekliği artırıldı
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                  ),
                  child: Column(
                    children: [
                      // Profil resmi - merkezi ve büyük
                      AnimatedBuilder(
                        animation: _colorAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 80, // Profil resmi boyutu büyütüldü
                            height: 80,
                            child: CustomPaint(
                              painter: ActivityRingPainter(
                                outerProgress: progress,
                                middleProgress: progress,
                                innerProgress: progress,
                                outerColor: Colors.white,
                                middleColor: Colors.white.withOpacity(0.7),
                                innerColor: Colors.white.withOpacity(0.4),
                                showGlow: true,
                              ),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 35, // Radius büyütüldü
                                  backgroundColor: _colorAnimation.value,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null 
                                      ? const Icon(Icons.person, size: 35, color: AppColors.primaryGreen)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 12), // Profil resmi ile isim arası boşluk
                      
                      // İsim ve düzenle butonu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Kullanıcı Adı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Font boyutu büyütüldü
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/profile');
                            },
                            tooltip: 'Profili Düzenle',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8), // İsim ile bilgiler arası boşluk
                      
                      // Profil bilgileri - ismin altında
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user != null
                              ? '${user.age} yaş • ${user.height.toInt()} cm • ${user.weight.toInt()} kg'
                              : 'Profil bilgileri eksik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildMenuItem(context, icon: Icons.home_outlined, title: 'Ana Ekran', route: '/home', isHome: true),
                  _buildMenuItem(context, icon: Icons.person_outline, title: 'Profilim', route: '/profile'),
                  _buildMenuItem(context, icon: Icons.monitor_heart_outlined, title: 'Kalori & Makro Takibi', route: '/calorie_tracking'),
                  _buildMenuItem(context, icon: Icons.emoji_events_outlined, title: 'Başarımlarım', route: '/achievements'),
                  const Divider(height: 12, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.assignment_outlined, title: 'Antrenman Planları', route: '/workout_plans'),
                  _buildMenuItem(context, icon: Icons.fitness_center_outlined, title: 'Fitness Egzersizleri', route: '/fitness'),
                  _buildMenuItem(context, icon: Icons.restaurant_menu_outlined, title: 'Yemek Kalorileri', route: '/food_calories'),
                  const Divider(height: 12, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.bar_chart_outlined, title: 'Raporlar ve Grafikler', route: '/reports'),
                  _buildMenuItem(context, icon: Icons.straighten_outlined, title: 'Vücut Ölçülerim', route: '/measurements'),
                  _buildMenuItem(context, icon: Icons.photo_camera_outlined, title: 'İlerleme Fotoğrafları', route: '/progress_photos'),
                  _buildMenuItem(context, icon: Icons.notifications_outlined, title: 'Hatırlatıcılar', route: '/reminders'),
                ],
              ),
            ),
            // İmza alanı
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
              child: Text(
                'Powered by Lucci FormdaKal 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String route, bool isHome = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 28,
      leading: Icon(icon, color: AppColors.primaryGreen, size: 20),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 14,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (isHome) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}