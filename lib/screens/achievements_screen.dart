// lib/screens/achievements_screen.dart - NAVİGASYON BAR DÜZELTMESİ + HATA DÜZELTİLDİ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F0000) : const Color(0xFFF2F2F7),
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
      body: SafeArea(
        bottom: true, // ÖNEMLİ: Navigasyon barının üstünde kal
        child: Consumer<AchievementProvider>(
          builder: (context, provider, child) {
            if (provider.achievements.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz görüntülenecek başarım yok.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final unlockedAchievements = provider.achievements.where((a) => a.isUnlocked).toList();
            final lockedAchievements = provider.achievements.where((a) => !a.isUnlocked).toList();

            return Column(
              children: [
                // İstatistik Kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.2),
                        Colors.orange.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.emoji_events,
                        label: 'Kazanılan',
                        value: unlockedAchievements.length.toString(),
                        color: Colors.amber,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.amber.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        icon: Icons.lock_outline,
                        label: 'Kilitli',
                        value: lockedAchievements.length.toString(),
                        color: Colors.grey,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.amber.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        icon: Icons.percent,
                        label: 'Tamamlama',
                        value: '${((unlockedAchievements.length / provider.achievements.length) * 100).toInt()}%',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                // Başarım Listesi
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.emoji_events, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Kazanılan (${unlockedAchievements.length})'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_outline, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Kilitli (${lockedAchievements.length})'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab View
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Kazanılan Başarımlar
                              _buildAchievementGrid(context, unlockedAchievements, true),
                              // Kilitli Başarımlar
                              _buildAchievementGrid(context, lockedAchievements, false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid(BuildContext context, List<Achievement> achievements, bool isUnlocked) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.emoji_events_outlined : Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked 
                ? 'Henüz kazanılmış başarım yok.\nEgzersiz yapmaya başla!'
                : 'Tüm başarımlar kazanılmış!\nTebrikler! 🎉',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(context, achievement);
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    final theme = Theme.of(context);
    final cardColor = isUnlocked ? achievement.color : Colors.grey.shade800;

    return GestureDetector(
      onTap: () => _showAchievementDetail(context, achievement),
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        shadowColor: isUnlocked ? cardColor.withOpacity(0.3) : Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnlocked
                  ? [cardColor.withOpacity(0.7), cardColor]
                  : [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlocked ? achievement.icon : Icons.lock_outline,
                  size: 20,
                  color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.5),
                    fontSize: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              achievement.isUnlocked ? achievement.icon : Icons.lock_outline,
              color: achievement.isUnlocked ? achievement.color : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                achievement.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Başarım Tamamlandı!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Henüz Tamamlanmadı',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAchievementStats(BuildContext context) {
    final provider = Provider.of<AchievementProvider>(context, listen: false);
    final unlockedCount = provider.achievements.where((a) => a.isUnlocked).length;
    final totalCount = provider.achievements.length;
    final completionRate = (unlockedCount / totalCount * 100).toInt();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.blue),
            SizedBox(width: 8),
            Text('Başarım İstatistikleri'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Toplam Başarım', totalCount.toString()),
            _buildStatRow('Kazanılan', unlockedCount.toString()),
            _buildStatRow('Kalan', (totalCount - unlockedCount).toString()),
            _buildStatRow('Tamamlanma Oranı', '%$completionRate'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: unlockedCount / totalCount,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}