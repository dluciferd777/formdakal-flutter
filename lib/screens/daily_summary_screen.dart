// lib/screens/daily_summary_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/daily_summary_card.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final GlobalKey _summaryCardKey = GlobalKey();

  void _shareSummary() {
    SocialShareManager.shareDailySummary(
      cardKey: _summaryCardKey,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Günlük Özetim'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSummary,
            tooltip: 'Özeti Paylaş',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ana Kart
                DailySummaryCard(shareKey: _summaryCardKey),
                
                const SizedBox(height: 30),
                
                // Paylaş Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareSummary,
                    icon: const Icon(Icons.share),
                    label: const Text('Sosyal Medyada Paylaş'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bilgi Metni
                Text(
                  'Günlük aktivite özetinizi arkadaşlarınızla paylaşın\nve motivasyonunuzu artırın! 💪',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}