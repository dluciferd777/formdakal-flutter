// lib/widgets/custom_drawer.dart
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
      width: 280, // Drawer genişliğini artırdık
      child: Drawer(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                  height: 160, // Header yüksekliğini artırdık
                  padding: const EdgeInsets.fromLTRB(16, 28, 12, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreen.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _colorAnimation,
                            builder: (context, child) {
                              return SizedBox(
                                width: 70, // Profil resmi boyutunu artırdık
                                height: 70,
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
                                      radius: 30, // Radius artırıldı
                                      backgroundColor: _colorAnimation.value,
                                      backgroundImage: imageProvider,
                                      child: imageProvider == null 
                                          ? const Icon(Icons.person, size: 30, color: AppColors.primaryGreen)
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.name ?? 'Kullanıcı Adı',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18, // Font boyutu artırıldı
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/profile');
                                      },
                                      tooltip: 'Profili Düzenle',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user != null
                                        ? '${user.age} yaş • ${user.height.toInt()} cm • ${user.weight.toInt()} kg'
                                        : 'Profil bilgileri eksik',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12, // Font boyutu artırıldı
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  _buildMenuItem(context, icon: Icons.emoji_events_outlined, title: 'Başarımlarım', route: '/achievements'),
                  _buildMenuItem(context, icon: Icons.assignment_outlined, title: 'Antrenman Planları', route: '/workout_plans'),
                  const Divider(height: 12, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.bar_chart_outlined, title: 'Raporlar ve Grafikler', route: '/reports'),
                  _buildMenuItem(context, icon: Icons.monitor_heart_outlined, title: 'Kalori & Makro Takibi', route: '/calorie_tracking'),
                  const Divider(height: 12, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.fitness_center_outlined, title: 'Fitness Egzersizleri', route: '/fitness'),
                  _buildMenuItem(context, icon: Icons.restaurant_menu_outlined, title: 'Yemek Kalorileri', route: '/food_calories'),
                  const Divider(height: 12, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.person_outline, title: 'Profilim', route: '/profile'),
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
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
                  fontSize: 11, // Font boyutu artırıldı
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required String route, bool isHome = false}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 32,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: AppColors.primaryGreen, 
            size: 22, // İkon boyutu artırıldı
          ),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontSize: 16, // Font boyutu artırıldı
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87, // Beyaz temada görünür renge çevrildi
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        onTap: () {
          Navigator.pop(context);
          if (isHome) {
            Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
          } else {
            Navigator.pushNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: AppColors.primaryGreen.withOpacity(0.05),
        splashColor: AppColors.primaryGreen.withOpacity(0.1),
      ),
    );
  }
}