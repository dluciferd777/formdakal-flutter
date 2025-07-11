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
    )..repeat(reverse: true); // Animasyonu tekrarla

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

  // Profil resmi için daha güvenilir bir görüntüleyici metot.
  ImageProvider? _buildProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    if (kIsWeb) {
      return NetworkImage(imagePath);
    } else {
      final file = File(imagePath);
      // Dosyanın gerçekten var olup olmadığını kontrol et.
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null; // Geçerli bir resim bulunamazsa null döndür.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Status bar yüksekliğini alarak profil alanının üst boşluğunu ayarla
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: 240, // Drawer genişliğini küçülttük
      child: Drawer(
        child: Column(
          children: [
            Consumer2<UserProvider, ExerciseProvider>(
              builder: (context, userProvider, exerciseProvider, child) {
                final user = userProvider.user;
                final imageProvider = _buildProfileImage(user?.profileImagePath);
                
                // Günlük yakılan kaloriye göre halka ilerlemesi
                final double dailyBurnedCalories = exerciseProvider.getDailyBurnedCalories(DateTime.now());
                // Hedef kaloriye göre ilerleme yüzdesi (örneğin 500 kalori hedef)
                final double calorieGoal = user?.dailyCalorieNeeds != null ? user!.dailyCalorieNeeds * 0.25 : 500;
                final double progress = (dailyBurnedCalories / calorieGoal).clamp(0.0, 1.0);

                return Container(
                  // Header yüksekliğini ve üst padding'i status bar'a göre ayarla
                  height: 140 + statusBarHeight, 
                  padding: EdgeInsets.fromLTRB(12, 24 + statusBarHeight, 8, 12), // Top padding'e status bar yüksekliği eklendi
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Profil resmi alanı
                          AnimatedBuilder(
                            animation: _colorAnimation,
                            builder: (context, child) {
                              return SizedBox(
                                width: 60, // Profil resmi boyutunu küçülttük
                                height: 60,
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
                                      radius: 25, // Radius küçültüldü
                                      backgroundColor: _colorAnimation.value,
                                      backgroundImage: imageProvider,
                                      child: imageProvider == null 
                                          ? const Icon(Icons.person, size: 25, color: AppColors.primaryGreen)
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8), // Boşluk küçültüldü
                          // İsim ve bilgiler
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
                                          fontSize: 15, // Font boyutu küçültüldü
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
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
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    user != null
                                        ? '${user.age} yaş • ${user.height.toInt()} cm • ${user.weight.toInt()} kg'
                                        : 'Profil bilgileri eksik',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10, // Font boyutu küçültüldü
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
                  const SizedBox(height: 4), // Üst boşluk
                  
                  // GRUP 1: ANA SAYFALAR
                  _buildMenuItem(context, icon: Icons.home_outlined, title: 'Ana Ekran', route: '/home', isHome: true),
                  _buildMenuItem(context, icon: Icons.person_outline, title: 'Profilim', route: '/profile'),
                  _buildMenuItem(context, icon: Icons.emoji_events_outlined, title: 'Başarımlarım', route: '/achievements'),
                  
                  const Divider(height: 16, thickness: 0.5, indent: 12, endIndent: 12),
                  
                  // GRUP 2: ANTRENMAN VE KALORİ
                  _buildMenuItem(context, icon: Icons.assignment_outlined, title: 'Antrenman Planları', route: '/workout_plans'),
                  _buildMenuItem(context, icon: Icons.monitor_heart_outlined, title: 'Kalori Takibi', route: '/calorie_tracking'),
                  _buildMenuItem(context, icon: Icons.fitness_center_outlined, title: 'Fitness Kalori', route: '/fitness'),
                  _buildMenuItem(context, icon: Icons.restaurant_menu_outlined, title: 'Yemek Kalori', route: '/food_calories'),
                  
                  const Divider(height: 16, thickness: 0.5, indent: 12, endIndent: 12),
                  
                  // GRUP 3: RAPORLAR VE TAKİP
                  _buildMenuItem(context, icon: Icons.bar_chart_outlined, title: 'Raporlar', route: '/reports'),
                  _buildMenuItem(context, icon: Icons.straighten_outlined, title: 'Ölçümlerim', route: '/measurements'),
                  _buildMenuItem(context, icon: Icons.photo_camera_outlined, title: 'Fotoğraflarım', route: '/progress_photos'),
                  _buildMenuItem(context, icon: Icons.notifications_outlined, title: 'Hatırlatıcılar', route: '/reminders'),
                ],
              ),
            ),
            // İmza alanı
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0), // Padding küçültüldü
              child: Text(
                'Powered by Lucci FormdaKal 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 9, // Font boyutu küçültüldü
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Padding'ler küçültüldü
      minLeadingWidth: 24, // Leading genişliği küçültüldü
      leading: Icon(icon, color: AppColors.primaryGreen, size: 18), // İkon boyutu küçültüldü
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 13, // Font boyutu küçültüldü
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
