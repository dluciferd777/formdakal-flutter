// lib/utils/theme.dart - İYİLEŞTİRİLMİŞ TEMA
import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static final _baseTextTheme = ThemeData.dark().textTheme;

  // --- AÇIK TEMA - KARTLAR DAHA BELİRGİN ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.lightSurface, // Hafif gri arka plan
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white, // AppBar'da beyaz yazı
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard, // Kartlar beyaz
      elevation: 0, // Elevation yerine shadow kullanacağız
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.lightCardBorderColor,
          width: 1,
        ),
      ),
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
        elevation: 0, // Flat tasarım
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
  );

  // --- KOYU TEMA - DAHA SERT SİYAH ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.darkBackground, // TAM SİYAH
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface, // TAM SİYAH
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard, // Kartlar hafif gri (siyah değil)
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.darkCardBorder,
          width: 0.5,
        ),
      ),
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
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
  );

  // CUSTOM CARD DECORATION METHODS
  static BoxDecoration lightCardDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.lightCard,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.darkCardBorder,
        width: 1,
      ),
      boxShadow: AppColors.lightCardShadow,
    );
  }

  static BoxDecoration darkCardDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.darkCard,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.darkCardBorder,
        width: 0.5,
      ),
      boxShadow: AppColors.darkCardShadow,
    );
  }

  // CONTEXT'E BAĞLI CARD DECORATION
  static BoxDecoration cardDecoration(BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark 
        ? darkCardDecoration(color: color, borderRadius: borderRadius)
        : lightCardDecoration(color: color, borderRadius: borderRadius);
  }
}