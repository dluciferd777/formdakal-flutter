// lib/utils/colors.dart - İYİLEŞTİRİLMİŞ VERSİYON
import 'package:flutter/material.dart';

class AppColors {
  // Ana FormdaKal Yeşil Rengi
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  
  // DARK TEMA - DAHA SERT SİYAH RENKLER
  static const Color darkBackground = Color(0xFF000000); // TAM SİYAH - Ana arka plan
  static const Color darkSurface = Color(0xFF000000);    // TAM SİYAH - Yüzeyler için
  static const Color darkCard = Color(0xFF1C1C1C);       // Kartlar için hafif gri (siyah değil)
  static const Color darkCardBorder = Color(0xFF2C2C2C); // Kart kenarları için
  
  // LIGHT TEMA - KARTLAR İÇİN İYİLEŞTİRİLMİŞ RENKLER
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);   // Daha soft arka plan
  static const Color lightCard = Color(0xFFFFFFFF);      // Kartlar beyaz
  static const Color lightCardShadowColor = Color(0xFFE5E7EB); // Kart gölge rengi
  static const Color lightCardBorderColor = Color(0xFFF1F3F4); // Kart kenar rengi
  
  // Metin Renkleri
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDark = Color(0xFF1F2937);        // Daha soft siyah
  static const Color textGray = Color(0xFF6B7280);
  
  // Aktivite Renkleri (Samsung Health tarzı)
  static const Color stepColor = Color(0xFF66BB6A);
  static const Color timeColor = Color(0xFF2196F3);
  static const Color calorieColor = Color(0xFFE91E63);
  
  // Progress Ring Renkleri
  static const Color ringGreen = Color(0xFF66BB6A);
  static const Color ringBlue = Color(0xFF2196F3);
  static const Color ringPink = Color(0xFFE91E63);
  static const Color ringOrange = Color(0xFFFF9800);
  
  // Durum Renkleri
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // GÖLGE RENKLERİ - İYİLEŞTİRİLMİŞ
  static const Color shadowLight = Color(0x0F000000);     // Hafif gölge
  static const Color shadowMedium = Color(0x1A000000);    // Orta gölge  
  static const Color shadowDark = Color(0x4D000000);      // Koyu gölge
  static const Color shadowVeryLight = Color(0x08000000); // Çok hafif gölge
  
  // KART GÖLGE DEFİNİSYONLARI
  static List<BoxShadow> get lightCardShadow => [
    BoxShadow(
      color: shadowLight,
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowVeryLight,
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get darkCardShadow => [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.3),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}