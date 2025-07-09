// lib/screens/achievements_screen.dart - KÜÇÜK EKRANLAR İÇİN DÜZELTİLMİŞ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import '../utils/colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F7),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        title: const Text(
          'Başarımlarım',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            onPressed: () => _showAchievementStats(context),
            tooltip: 'İstatistikler',
          ),
        ],
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, child) {
          if (provider.achievements.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return Column(
            children: [
              // Stats Header - Küçük ekranlar için optimize edildi
              _buildStatsHeader(provider, isDarkMode, screenHeight),

              // Tab Bar - Daha küçük yapıldı
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12), // 16'dan 12'ye
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12), // 16'dan 12'ye
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15, // 20'den 15'e
                            offset: const Offset(0, 3), // 5'ten 3'e
                          ),
                        ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // 12'den 8'e
                    color: AppColors.primaryGreen,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), // 12'den 11'e
                  dividerColor: Colors.transparent,
                  onTap: (index) => HapticFeedback.selectionClick(),
                  tabs: const [
                    Tab(text: 'Tümü'),
                    Tab(text: 'Günlük'),
                    Tab(text: 'Haftalık'),
                    Tab(text: 'Aylık'),
                  ],
                ),
              ),

              const SizedBox(height: 8), // Boşluk eklendi

              // Tab Content - Overflow önlendi
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAchievementGrid(provider.achievements, isDarkMode, screenWidth, screenHeight),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.daily), isDarkMode, screenWidth, screenHeight),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.weekly), isDarkMode, screenWidth, screenHeight),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.monthly), isDarkMode, screenWidth, screenHeight),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // FloatingActionButton - Küçük ekranlar için pozisyon ayarlandı
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Alt padding eklendi
        child: FloatingActionButton.extended(
          onPressed: () => _showTestDialog(context),
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.science_rounded, color: Colors.white, size: 20), // İkon küçültüldü
          label: const Text(
            'Test',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), // Font küçültüldü
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24), // 32'den 24'e
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 60, // 80'den 60'a
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 24), // 32'den 24'e
          Text(
            'Henüz Başarım Yok',
            style: TextStyle(
              fontSize: 20, // 24'ten 20'ye
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8), // 12'den 8'e
          Text(
            'Aktivitelere başlayarak\nilk başarımını kazanmaya başla!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, // 16'dan 14'e
              color: Colors.grey.shade500,
              height: 1.4, // 1.5'ten 1.4'e
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(AchievementProvider provider, bool isDarkMode, double screenHeight) {
    // Küçük ekranlar için header boyutunu ayarla
    final bool isSmallScreen = screenHeight < 700;
    
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16), // Küçük ekranlarda daha az margin
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20), // Küçük ekranlarda daha az padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // 20'den 16'ya
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 12, // 15'ten 12'ye
            offset: const Offset(0, 4), // 5'ten 4'e
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 60 : 80, // Küçük ekranlarda daha küçük
            height: isSmallScreen ? 60 : 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: provider.completionPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: isSmallScreen ? 6 : 8, // Küçük ekranlarda ince
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${provider.completionPercentage.toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14 : 16, // Küçük ekranlarda küçük font
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tamamlandı',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 7 : 8, // Küçük ekranlarda çok küçük
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 16 : 20), // Küçük ekranlarda daha az boşluk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.unlockedCount}/${provider.totalAchievements}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 24 : 28, // Küçük ekranlarda küçük font
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Başarım Kazanıldı',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 12 : 14, // Küçük ekranlarda küçük font
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12), // Küçük ekranlarda daha az boşluk
                Row(
                  children: [
                    _buildMiniStat('Bugün', provider.todayProgress.toString(), Icons.today, isSmallScreen),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    _buildMiniStat('Bu Hafta', provider.weeklyProgress.toString(), Icons.date_range, isSmallScreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: isSmallScreen ? 14 : 16),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isSmallScreen ? 10 : 12, // Küçük ekranlarda küçük font
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid(List<Achievement> achievements, bool isDarkMode, double screenWidth, double screenHeight) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Bu kategoride henüz başarım yok',
          style: TextStyle(
            fontSize: 14, // 16'dan 14'e
            color: Colors.grey.shade500,
          ),
        ),
      );
    }

    // Ekran boyutuna göre grid ayarları
    final bool isSmallScreen = screenHeight < 700;
    final bool isNarrowScreen = screenWidth < 400;
    
    // crossAxisCount'u ekran boyutuna göre ayarla
    int crossAxisCount = 2;
    if (isNarrowScreen) {
      crossAxisCount = 1; // Çok dar ekranlarda tek sütun
    }
    
    // childAspectRatio'yu ekran boyutuna göre ayarla
    double childAspectRatio = 1.0;
    if (isSmallScreen) {
      childAspectRatio = 1.3; // Küçük ekranlarda daha geniş kartlar
    }
    if (isNarrowScreen) {
      childAspectRatio = 2.5; // Tek sütunda çok geniş kartlar
    }

    return GridView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Küçük ekranlarda daha az padding
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isSmallScreen ? 12 : 16, // Küçük ekranlarda daha az boşluk
        mainAxisSpacing: isSmallScreen ? 12 : 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            final animationProgress = Curves.elasticOut.transform(
              (_cardAnimationController.value - (index * 0.1)).clamp(0.0, 1.0),
            );

            return Transform.scale(
              scale: animationProgress,
              child: _buildAchievementCard(achievement, isDarkMode, isSmallScreen, isNarrowScreen),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDarkMode, bool isSmallScreen, bool isNarrowScreen) {
    final bool isUnlocked = achievement.isUnlocked;
    final cardColor = isUnlocked ? achievement.color : Colors.grey.shade700;
    final progress = achievement.currentValue / achievement.targetValue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetails(achievement);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16), // Küçük ekranlarda daha az radius
          gradient: LinearGradient(
            colors: isUnlocked
                ? [cardColor.withOpacity(0.8), cardColor]
                : [Colors.grey.shade700, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? cardColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: isUnlocked ? (isSmallScreen ? 8 : 12) : (isSmallScreen ? 4 : 6),
              offset: Offset(0, isSmallScreen ? 2 : 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Küçük ekranlarda daha az padding
          child: isNarrowScreen 
              ? _buildHorizontalLayout(achievement, isUnlocked, progress, isSmallScreen)
              : _buildVerticalLayout(achievement, isUnlocked, progress, isSmallScreen),
        ),
      ),
    );
  }

  // Dar ekranlar için yatay layout
  Widget _buildHorizontalLayout(Achievement achievement, bool isUnlocked, double progress, bool isSmallScreen) {
    return Row(
      children: [
        // İkon ve progress
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              if (!isUnlocked && achievement.targetValue > 1)
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  strokeWidth: 3,
                ),
              Center(
                child: Icon(
                  isUnlocked ? achievement.icon : Icons.lock_outline,
                  size: 24,
                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Metin bilgileri
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                achievement.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.6),
                  fontSize: 11,
                ),
              ),
              if (!isUnlocked && achievement.targetValue > 1) ...[
                const SizedBox(height: 4),
                Text(
                  '${achievement.currentValue}/${achievement.targetValue}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Normal ekranlar için dikey layout
  Widget _buildVerticalLayout(Achievement achievement, bool isUnlocked, double progress, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // İkon ve progress
        SizedBox(
          width: isSmallScreen ? 50 : 60, // Küçük ekranlarda daha küçük
          height: isSmallScreen ? 50 : 60,
          child: Stack(
            children: [
              if (!isUnlocked && achievement.targetValue > 1)
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  strokeWidth: isSmallScreen ? 3 : 4,
                ),
              Center(
                child: Icon(
                  isUnlocked ? achievement.icon : Icons.lock_outline,
                  size: isSmallScreen ? 24 : 32, // Küçük ekranlarda daha küçük
                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12), // Küçük ekranlarda daha az boşluk
        
        // Başlık
        Text(
          achievement.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: isSmallScreen ? 12 : 14, // Küçük ekranlarda daha küçük font
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8), // Küçük ekranlarda daha az boşluk
        
        // Açıklama
        Text(
          achievement.description,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.6),
            fontSize: isSmallScreen ? 10 : 11, // Küçük ekranlarda daha küçük font
          ),
        ),
        
        // Progress metni
        if (!isUnlocked && achievement.targetValue > 1) ...[
          SizedBox(height: isSmallScreen ? 4 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8, 
              vertical: isSmallScreen ? 2 : 4
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // 12'den 10'a
            ),
            child: Text(
              '${achievement.currentValue}/${achievement.targetValue}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 9 : 10, // Küçük ekranlarda daha küçük font
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Diğer metodlar aynı kalacak...
  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(achievement.icon, color: achievement.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: achievement.currentValue / achievement.targetValue,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
            ),
            const SizedBox(height: 8),
            Text(
              'İlerleme: ${achievement.currentValue}/${achievement.targetValue}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Tür: ${_getTypeText(achievement.type)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showAchievementStats(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Başarım İstatistikleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Toplam Başarım', provider.totalAchievements.toString()),
            _buildStatRow('Kazanılan', provider.unlockedCount.toString()),
            _buildStatRow('Tamamlanma Oranı', '%${provider.completionPercentage.toInt()}'),
            _buildStatRow('Bugünkü İlerleme', provider.todayProgress.toString()),
            _buildStatRow('Haftalık İlerleme', provider.weeklyProgress.toString()),
            _buildStatRow('Aylık İlerleme', provider.monthlyProgress.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showTestDialog(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Test Başarımları'),
        content: const Text('Hangi başarımı test etmek istiyorsun?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.unlockAchievement('first_login');
            },
            child: const Text('Hoş Geldin'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.addProgress('daily_steps_6000', 6000);
            },
            child: const Text('Günlük Adım'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.addProgress('first_workout', 1);
            },
            child: const Text('İlk Antrenman'),
          ),
        ],
      ),
    );
  }

  String _getTypeText(AchievementType type) {
    switch (type) {
      case AchievementType.daily:
        return 'Günlük';
      case AchievementType.weekly:
        return 'Haftalık';
      case AchievementType.monthly:
        return 'Aylık';
      case AchievementType.permanent:
        return 'Kalıcı';
    }
  }
}