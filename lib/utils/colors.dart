// lib/utils/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Ana FormdaKal Yeşil Rengi - DAHA PARLAK BİR TON İLE GÜNCELLENDİ
  static const Color primaryGreen = Color(0xFF4CAF50); // Önceki: 0xFF66BB6A - Daha parlak bir yeşil tonu
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  
  // Koyu Tema Renkleri
  static const Color darkBackground = Color(0xFF000000); // TAM SİYAH
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  
  // Açık Tema Renkleri
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  
  // Metin Renkleri
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDark = Color(0xFF000000);
  static const Color textGray = Color(0xFF757575);
  
  // Aktivite Renkleri (Samsung Health tarzı)
  static const Color stepColor = Color(0xFF66BB6A);  // Yeşil - Adım (Ana renkle uyumlu hale getirildi)
  static const Color timeColor = Color(0xFF2196F3);  // Mavi - Zaman
  static const Color calorieColor = Color(0xFFE91E63); // Pembe - Kalori
  
  // Progress Ring Renkleri
  static const Color ringGreen = Color(0xFF66BB6A); // Ana renkle uyumlu hale getirildi
  static const Color ringBlue = Color(0xFF2196F3);
  static const Color ringPink = Color(0xFFE91E63);
  static const Color ringOrange = Color(0xFFFF9800);
  
  // Durum Renkleri
  static const Color success = Color(0xFF66BB6A); // Ana renkle uyumlu hale getirildi
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Gölge Renkleri
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3D000000);
}
