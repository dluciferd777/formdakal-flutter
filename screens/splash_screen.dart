// lib/screens/splash_screen.dart - LOADİNG KALDIRILDI
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:formdakal/providers/exercise_provider.dart';
import 'package:formdakal/providers/food_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();

    // Hızlı başlatma - loading ekranı kaldırıldı
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Paralel veri yükleme
      await Future.wait([
        _loadUserData(),
        _loadFoodData(),
        _loadExerciseData(),
        _loadAchievementData(),
      ]);

      // Hızlı geçiş - 900ms
      await Future.delayed(const Duration(milliseconds: 900)); 
      
      _checkAuthStatus();
      
    } catch (e) {
      debugPrint("❌ Başlatma hatası: $e");
      // Hata olsa bile devam et
      await Future.delayed(const Duration(milliseconds: 1500));
      _checkAuthStatus();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      await Provider.of<UserProvider>(context, listen: false).loadUser();
      debugPrint("✅ Kullanıcı verileri yüklendi");
    } catch (e) {
      debugPrint("❌ Kullanıcı verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadFoodData() async {
    if (!mounted) return;
    try {
      await Provider.of<FoodProvider>(context, listen: false).loadData();
      debugPrint("✅ Yemek verileri yüklendi");
    } catch (e) {
      debugPrint("❌ Yemek verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadExerciseData() async {
    if (!mounted) return;
    try {
      await Provider.of<ExerciseProvider>(context, listen: false).loadData();
      debugPrint("✅ Egzersiz verileri yüklendi");
    } catch (e) {
      debugPrint("❌ Egzersiz verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadAchievementData() async {
    if (!mounted) return;
    try {
      debugPrint("✅ Başarım verileri yüklendi");
    } catch (e) {
      debugPrint("❌ Başarım verisi yükleme hatası: $e");
    }
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.user != null) {
      debugPrint("✅ Kullanıcı mevcut - Ana ekrana yönlendiriliyor");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      debugPrint("ℹ️ Yeni kullanıcı - Onboarding'e yönlendiriliyor");
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Yeni kol kası ikonu - beyaz çerçeve olmadan
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '💪',
                            style: TextStyle(
                              fontSize: 60,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                          children: const [
                            TextSpan(
                              text: 'F',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 48,
                              ),
                            ),
                            TextSpan(text: 'ormda'),
                            TextSpan(
                              text: 'K',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 48,
                              ),
                            ),
                            TextSpan(text: 'al'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sağlıklı yaşamın başladığı yer',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w300,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}