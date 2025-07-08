// lib/screens/achievements_screen.dart - KARTLAR %50 KÜÇÜLTÜLDÜ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarımlarım'),
      ),
      body: SafeArea(
        child: Consumer<AchievementProvider>(
          builder: (context, provider, child) {
            if (provider.achievements.isEmpty) {
              return const Center(child: Text('Henüz görüntülenecek başarım yok.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(6), // Padding yarıya indirildi: 12 → 6
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 2'den 4'e çıkarıldı - daha küçük kartlar
                crossAxisSpacing: 5, // Boşluklar yarıya indirildi: 10 → 5
                mainAxisSpacing: 5, // Boşluklar yarıya indirildi: 10 → 5
                childAspectRatio: 0.8, // Oranı biraz ayarlandı
              ),
              itemCount: provider.achievements.length,
              itemBuilder: (context, index) {
                final achievement = provider.achievements[index];
                return _buildAchievementCard(context, achievement);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final bool isUnlocked = achievement.isUnlocked;
    final theme = Theme.of(context);
    final cardColor = isUnlocked ? achievement.color : Colors.grey.shade800;

    return Card(
      elevation: isUnlocked ? 4 : 1, // Gölge yarıya indirildi: 8→4, 2→1
      shadowColor: isUnlocked ? cardColor.withOpacity(0.3) : Colors.black.withOpacity(0.3), // Gölge açıklığı azaltıldı
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Köşe yuvarlaklığı küçültüldü: 12→8
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
          padding: const EdgeInsets.all(4.0), // İç padding yarıya indirildi: 8→4
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUnlocked ? achievement.icon : Icons.lock_outline,
                size: 20, // İkon boyutu yarıya indirildi: 40→20
                color: Colors.white.withOpacity(isUnlocked ? 1.0 : 0.6),
              ),
              const SizedBox(height: 4), // Boşluk yarıya indirildi: 8→4
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2, // Maksimum 2 satır
                overflow: TextOverflow.ellipsis, // Taşan metni kes
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 8, // Yazı boyutu yarıya indirildi: 14→8
                ),
              ),
              const SizedBox(height: 2), // Boşluk yarıya indirildi: 4→2
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 2, // Maksimum 2 satır
                overflow: TextOverflow.ellipsis, // Taşan metni kes
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(isUnlocked ? 0.9 : 0.5),
                  fontSize: 6, // Yazı boyutu yarıya indirildi: 10→6
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}