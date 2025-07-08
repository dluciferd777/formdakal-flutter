// lib/screens/splash_screen.dart - HIZLI BAŞLATMA VE BAŞLIK GÖRSELİ DÜZELTMESİ
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
  
  bool _isLoading = true;
  String _loadingText = 'Başlatılıyor...';

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

    // Paralel veri yükleme - PERFORMANS İYİLEŞTİRMESİ
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingText = 'Veriler yükleniyor...';
      });

      // TÜM PROVİDER'LARI PARALEL YÜKLE - HIZLI BAŞLATMA
      await Future.wait([
        _loadUserData(),
        _loadFoodData(),
        _loadExerciseData(),
        _loadAchievementData(),
      ]);

      setState(() {
        _loadingText = 'Hazırlanıyor...';
      });

      // Minimum splash süresi 1 saniyeye çıkarıldı
      await Future.delayed(const Duration(seconds: 1)); 
      
      _checkAuthStatus();
      
    } catch (e) {
      print("❌ Başlatma hatası: $e");
      
      setState(() {
        _loadingText = 'Hata oluştu, yeniden deneniyor...';
      });
      
      // Hata durumunda yeniden dene
      await Future.delayed(const Duration(seconds: 1));
      _checkAuthStatus();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      await Provider.of<UserProvider>(context, listen: false).loadUser();
      print("✅ Kullanıcı verileri yüklendi");
    } catch (e) {
      print("❌ Kullanıcı verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadFoodData() async {
    if (!mounted) return;
    try {
      await Provider.of<FoodProvider>(context, listen: false).loadData();
      print("✅ Yemek verileri yüklendi");
    } catch (e) {
      print("❌ Yemek verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadExerciseData() async {
    if (!mounted) return;
    try {
      await Provider.of<ExerciseProvider>(context, listen: false).loadData();
      print("✅ Egzersiz verileri yüklendi");
    } catch (e) {
      print("❌ Egzersiz verisi yükleme hatası: $e");
    }
  }

  Future<void> _loadAchievementData() async {
    if (!mounted) return;
    try {
      // AchievementProvider constructor'da zaten yüklüyor
      print("✅ Başarım verileri yüklendi");
    } catch (e) {
      print("❌ Başarım verisi yükleme hatası: $e");
    }
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Kullanıcı verisi kontrolü
    if (userProvider.user != null) {
      print("✅ Kullanıcı mevcut - Ana ekrana yönlendiriliyor");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("ℹ️ Yeni kullanıcı - Onboarding'e yönlendiriliyor");
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
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 30),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.displaySmall?.copyWith( // displaySmall kullanıldı
                                fontWeight: FontWeight.bold, // Kalın
                                color: isDarkMode ? Colors.white : Colors.black, // Tema rengine göre renk
                              ),
                          children: const [
                            TextSpan(
                              text: 'F',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 48,
                                // fontStyle: FontStyle.italic, // İtalik kaldırıldı
                                // fontWeight: FontWeight.bold, // Zaten ana stilde var, tekrara gerek yok
                              ),
                            ),
                            TextSpan(text: 'ormda'),
                            TextSpan(
                              text: 'K',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 48,
                                // fontStyle: FontStyle.italic, // İtalik kaldırıldı
                                // fontWeight: FontWeight.bold, // Zaten ana stilde var, tekrara gerek yok
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
                      const SizedBox(height: 50),
                      if (_isLoading) ...[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loadingText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryGreen,
                              ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryGreen,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hazır!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
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
