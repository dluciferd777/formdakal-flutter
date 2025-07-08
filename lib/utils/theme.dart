// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static final _baseTextTheme = ThemeData.dark().textTheme;

  // --- AÇIK TEMA ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.lightSurface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      // DÜZELTME: Beyaz tema için ikon ve yazı rengi siyah olmalı
      foregroundColor: AppColors.textDark, 
      elevation: 2,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        // DÜZELTME: Bu başlık rengi özel durumlarda (örneğin renkli appbar) kullanılabilir,
        // genel foregroundColor'ı ezmemesi için şimdilik beyaz bırakılabilir.
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    textTheme: _baseTextTheme.copyWith(
      displayLarge: _baseTextTheme.displayLarge?.copyWith(color: AppColors.textDark),
      displayMedium: _baseTextTheme.displayMedium?.copyWith(color: AppColors.textDark),
      displaySmall: _baseTextTheme.displaySmall?.copyWith(color: AppColors.textDark),
      headlineLarge: _baseTextTheme.headlineLarge?.copyWith(color: AppColors.textDark),
      headlineMedium: _baseTextTheme.headlineMedium?.copyWith(color: AppColors.textDark),
      headlineSmall: _baseTextTheme.headlineSmall?.copyWith(color: AppColors.textDark),
      titleLarge: _baseTextTheme.titleLarge?.copyWith(color: AppColors.textDark),
      titleMedium: _baseTextTheme.titleMedium?.copyWith(color: AppColors.textDark),
      titleSmall: _baseTextTheme.titleSmall?.copyWith(color: AppColors.textDark),
      bodyLarge: _baseTextTheme.bodyLarge?.copyWith(color: AppColors.textDark),
      bodyMedium: _baseTextTheme.bodyMedium?.copyWith(color: AppColors.textDark),
      bodySmall: _baseTextTheme.bodySmall?.copyWith(color: AppColors.textGray),
      labelLarge: _baseTextTheme.labelLarge?.copyWith(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: AppColors.textDark),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
    ),
  );

  // --- KOYU TEMA ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
    textTheme: _baseTextTheme.copyWith(
      displayLarge: _baseTextTheme.displayLarge?.copyWith(color: AppColors.textPrimary),
      displayMedium: _baseTextTheme.displayMedium?.copyWith(color: AppColors.textPrimary),
      displaySmall: _baseTextTheme.displaySmall?.copyWith(color: AppColors.textPrimary),
      headlineLarge: _baseTextTheme.headlineLarge?.copyWith(color: AppColors.textPrimary),
      headlineMedium: _baseTextTheme.headlineMedium?.copyWith(color: AppColors.textPrimary),
      headlineSmall: _baseTextTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
      titleLarge: _baseTextTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
      titleMedium: _baseTextTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      titleSmall: _baseTextTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
      bodyLarge: _baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: _baseTextTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      bodySmall: _baseTextTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge: _baseTextTheme.labelLarge?.copyWith(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
    ),
  );
}