// lib/screens/achievements_screen.dart - OVERFLOW HATASI DÜZELTİLDİ
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

    // Kartları sırayla animate et
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
              // Stats Header
              _buildStatsHeader(provider, isDarkMode),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primaryGreen,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAchievementGrid(provider.achievements, isDarkMode),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.daily), isDarkMode),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.weekly), isDarkMode),
                    _buildAchievementGrid(provider.getAchievementsByType(AchievementType.monthly), isDarkMode),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTestDialog(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.science_rounded, color: Colors.white),
        label: const Text(
          'Test Başarımları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Henüz Başarım Yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aktivitelere başlayarak\nilk başarımını kazanmaya başla!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(AchievementProvider provider, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: provider.completionPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 8,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${provider.completionPercentage.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Tamamlandı',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.unlockedCount}/${provider.totalAchievements}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Başarım Kazanıldı',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniStat('Bugün', provider.todayProgress.toString(), Icons.today),
                    const SizedBox(width: 16),
                    _buildMiniStat('Bu Hafta', provider.weeklyProgress.toString(), Icons.date_range),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid(List<Achievement> achievements, bool isDarkMode) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Bu kategoride henüz başarım yok',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 3'ten 2'ye değiştirildi - daha fazla alan
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // 0.85'ten 1.1'e yükseltildi - daha geniş kartlar
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
              child: _buildAchievementCard(achievement, isDarkMode),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDarkMode) {
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
          borderRadius: BorderRadius.circular(16),
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
              blurRadius: isUnlocked ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Padding artırıldı
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon ve progress
              SizedBox(
                width: 60, // Boyut artırıldı
                height: 60,
                child: Stack(
                  children: [
                    if (!isUnlocked && achievement.targetValue > 1)
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 4, // Kalınlık artırıldı
                      ),
                    Center(
                      child: Icon(
                        isUnlocked ? achievement.icon : Icons.lock_outline,
                        size: 32, // Boyut artırıldı
                        color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Başlık
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14, // Font boyutu artırıldı
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Açıklama - Daha kısa tutuldu
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 1, // Sadece 1 satır
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.6),
                  fontSize: 11,
                ),
              ),
              
              // Progress metni
              if (!isUnlocked && achievement.targetValue > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${achievement.currentValue}/${achievement.targetValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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