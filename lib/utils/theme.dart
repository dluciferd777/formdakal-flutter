// lib/utils/theme.dart - DÜZENLENMIŞ APPBAR TEMALARI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // BEYAZ TEMADA APPBAR YEŞİL
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white, // İkonlar ve yazılar beyaz
      elevation: 2,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Status bar ikonları beyaz
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: Colors.white, // Başlık beyaz
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white, // AppBar ikonları beyaz
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: Colors.white, // Action ikonları beyaz
        size: 24,
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
      // KOYU TEMADA APPBAR SİYAH/KOYU GRİ
      backgroundColor: AppColors.darkSurface, // Siyah/koyu gri
      foregroundColor: Colors.white, // İkonlar ve yazılar beyaz
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Status bar ikonları beyaz
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: Colors.white, // Başlık beyaz
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white, // AppBar ikonları beyaz
        size: 24,
      ),
      actionsIconTheme: const IconThemeData(
        color: Colors.white, // Action ikonları beyaz
        size: 24,
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

  // ÖZEL APPBAR WIDGET - TUTARLI KULLANIM İÇİN
  static AppBar buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(title),
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: isDarkMode ? 0 : 2,
      centerTitle: true,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }
}