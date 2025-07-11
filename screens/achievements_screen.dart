// lib/screens/achievements_screen.dart - OVERFLOW HATASI DÜZELTİLDİ + TUTARLI APPBAR
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen, // Temaya göre renk
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Başarımlarım',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [AppColors.primaryGreen.withOpacity(0.1), theme.scaffoldBackgroundColor]
                : [AppColors.primaryGreen.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Consumer<AchievementProvider>(
            builder: (context, provider, child) {
              if (provider.achievements.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz başarım yok.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hedeflerine ulaşarak başarımlar kazan!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Kilitleri ve açıkları ayır
              final unlockedAchievements = provider.achievements
                  .where((a) => a.isUnlocked)
                  .toList();
              final lockedAchievements = provider.achievements
                  .where((a) => !a.isUnlocked)
                  .toList();

              return CustomScrollView(
                slivers: [
                  // İstatistik banner
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.8),
                            AppColors.primaryGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Kazanılan',
                            unlockedAchievements.length.toString(),
                            Icons.emoji_events,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            'Kilitli',
                            lockedAchievements.length.toString(),
                            Icons.lock_outline,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem(
                            'Toplam',
                            provider.achievements.length.toString(),
                            Icons.flag,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kazanılan başarımlar
                  if (unlockedAchievements.isNotEmpty) ...[
                    _buildSectionHeader('🏆 Kazanılan Başarımlar'),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.9, // Kart boyutunu daha kareye yakın hale getirdik
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAchievementCard(unlockedAchievements[index], true),
                          childCount: unlockedAchievements.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Kilitli başarımlar
                  if (lockedAchievements.isNotEmpty) ...[
                    _buildSectionHeader('🔒 Kilitli Başarımlar'),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.9, // Kart boyutunu daha kareye yakın hale getirdik
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAchievementCard(lockedAchievements[index], false),
                          childCount: lockedAchievements.length,
                        ),
                      ),
                    ),
                  ],
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    final cardColor = isUnlocked ? achievement.color : Colors.grey.shade600;

    return Card(
      elevation: isUnlocked ? 8 : 3,
      shadowColor: isUnlocked 
          ? cardColor.withOpacity(0.4) 
          : Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [cardColor.withOpacity(0.8), cardColor]
                : [Colors.grey.shade600, Colors.grey.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Padding'i biraz artırdık
          child: Column(
            children: [
              // İkon kısmı - sabit boyut
              Container(
                height: 48, // Boyutu biraz büyüttük
                width: 48, // Boyutu biraz büyüttük
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Icon(
                  isUnlocked ? achievement.icon : Icons.lock_outline,
                  size: 26, // İkon boyutunu biraz büyüttük
                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.7),
                ),
              ),
              
              const SizedBox(height: 8), // Boşluğu artırdık
              
              // Başlık - Expanded ile esnek alan
              Expanded(
                flex: 2,
                child: Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12, // Font boyutunu artırdık
                  ),
                ),
              ),
              
              // Açıklama - Expanded ile esnek alan
              Expanded(
                flex: 2,
                child: Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.6),
                    fontSize: 9, // Font boyutunu artırdık
                  ),
                ),
              ),
              
              // Durum göstergesi
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Padding'i artırdık
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10), // Yuvarlaklığı artırdık
                  ),
                  child: const Text(
                    'Tamamlandı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8, // Font boyutunu artırdık
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
