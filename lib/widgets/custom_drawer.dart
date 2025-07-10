// lib/widgets/custom_drawer.dart - OVERFLOW SORUNU DÜZELTİLDİ
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
      width: 260,
      child: Drawer(
        child: Column(
          children: [
            // Header - SafeArea ile sarılı
            SafeArea(
              bottom: false,
              child: Consumer2<UserProvider, ExerciseProvider>(
                builder: (context, userProvider, exerciseProvider, child) {
                  final user = userProvider.user;
                  final imageProvider = _buildProfileImage(user?.profileImagePath);
                  
                  final double dailyBurnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
                  final double calorieGoal = user?.dailyCalorieNeeds != null ? user!.dailyCalorieNeeds * 0.25 : 500;
                  final double progress = (dailyBurnedCalories / calorieGoal).clamp(0.0, 1.0);

                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                    ),
                    child: Row(
                      children: [
                        // Profil resmi alanı - Kompakt
                        AnimatedBuilder(
                          animation: _colorAnimation,
                          builder: (context, child) {
                            return SizedBox(
                              width: 65,
                              height: 65,
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
                                    radius: 26,
                                    backgroundColor: _colorAnimation.value,
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null 
                                        ? const Icon(Icons.person, size: 26, color: AppColors.primaryGreen)
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        // İsim ve bilgiler - Tek satırda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user?.name ?? 'Kullanıcı',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/profile');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                              // Bilgiler tek satırda, kısa
                              if (user != null) 
                                Text(
                                  '${user.age}y • ${user.height.toInt()}cm • ${user.weight.toInt()}kg',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Menu items - Expanded ile overflow önlendi
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildMenuItem(context, icon: Icons.home_outlined, title: 'Ana Ekran', route: '/home', isHome: true),
                  _buildMenuItem(context, icon: Icons.emoji_events_outlined, title: 'Başarımlarım', route: '/achievements'),
                  _buildMenuItem(context, icon: Icons.assignment_outlined, title: 'Antrenman Planları', route: '/workout_plans'),
                  const Divider(height: 8, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.bar_chart_outlined, title: 'Raporlar', route: '/reports'),
                  _buildMenuItem(context, icon: Icons.monitor_heart_outlined, title: 'Kalori Takibi', route: '/calorie_tracking'),
                  const Divider(height: 8, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.fitness_center_outlined, title: 'Fitness', route: '/fitness'),
                  _buildMenuItem(context, icon: Icons.restaurant_menu_outlined, title: 'Yemek Kalorileri', route: '/food_calories'),
                  const Divider(height: 8, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildMenuItem(context, icon: Icons.person_outline, title: 'Profilim', route: '/profile'),
                  _buildMenuItem(context, icon: Icons.straighten_outlined, title: 'Ölçülerim', route: '/measurements'),
                  _buildMenuItem(context, icon: Icons.photo_camera_outlined, title: 'Fotoğraflar', route: '/progress_photos'),
                  _buildMenuItem(context, icon: Icons.notifications_outlined, title: 'Hatırlatıcılar', route: '/reminders'),
                ],
              ),
            ),
            
            // İmza alanı - SafeArea ile korumalı
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'FormdaKal v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String route, 
    bool isHome = false
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 28,
      leading: Icon(icon, color: AppColors.primaryGreen, size: 20),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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