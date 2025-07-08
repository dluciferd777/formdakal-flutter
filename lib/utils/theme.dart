// lib/utils/theme.dart - MODERN iOS 17 / MATERIAL YOU TARZI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

class AppTheme {
  // Typography Scale - Apple San Francisco / Google Sans benzeri
  static const _fontFamily = 'SF Pro Display'; // iOS benzeri (fallback: system)
  
  static const TextTheme _baseTextTheme = TextTheme(
    // Display (Büyük başlıklar)
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    
    // Headlines (Ana başlıklar)
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    
    // Titles (Başlık metinleri)
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    
    // Body (Gövde metinleri)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    
    // Labels (Etiket metinleri)
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  // --- AÇIK TEMA (iOS 17 / Material You Light) ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
      secondary: AppColors.lightGreen,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textDark,
      background: AppColors.lightBackground,
      onBackground: AppColors.textDark,
      error: AppColors.error,
      onError: Colors.white,
    ),
    
    // AppBar Theme (Modern iOS benzeri)
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: _baseTextTheme.titleLarge?.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w600,
      ),
      toolbarTextStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textDark,
      ),
    ),
    
    // Card Theme (iOS 17 Card style)
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    
    // ElevatedButton Theme (Modern iOS button)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        shadowColor: AppColors.primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // TextButton Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // OutlinedButton Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // FloatingActionButton Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // InputDecoration Theme (Modern form fields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade600,
      ),
      hintStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade400,
      ),
    ),
    
    // Switch Theme (iOS style)
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.grey.shade400;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryGreen;
        }
        return Colors.grey.shade300;
      }),
    ),
    
    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryGreen,
      inactiveTrackColor: Colors.grey.shade300,
      thumbColor: AppColors.primaryGreen,
      overlayColor: AppColors.primaryGreen.withOpacity(0.2),
      valueIndicatorColor: AppColors.primaryGreen,
    ),
    
    // BottomNavigationBar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _baseTextTheme.labelSmall,
    ),
    
    // Divider Theme
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 0.5,
      space: 1,
    ),
    
    // Text Theme
    textTheme: _baseTextTheme.apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.textDark,
      size: 24,
    ),
    
    // Primary Icon Theme
    primaryIconTheme: const IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  );

  // --- KOYU TEMA (iOS 17 / Material You Dark) ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGreen,
      onPrimary: Colors.black,
      secondary: AppColors.lightGreen,
      onSecondary: Colors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimary,
      background: AppColors.darkBackground,
      onBackground: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
    
    // AppBar Theme (Dark mode)
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: _baseTextTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      toolbarTextStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
    ),
    
    // Card Theme (Dark mode)
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    
    // ElevatedButton Theme (Dark mode)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor: Colors.grey.shade600,
        shadowColor: AppColors.primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // TextButton Theme (Dark mode)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // OutlinedButton Theme (Dark mode)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // FloatingActionButton Theme (Dark mode)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // InputDecoration Theme (Dark mode)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade400,
      ),
      hintStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade600,
      ),
    ),
    
    // Switch Theme (Dark mode)
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.black;
        }
        return Colors.grey.shade600;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryGreen;
        }
        return Colors.grey.shade700;
      }),
    ),
    
    // Slider Theme (Dark mode)
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryGreen,
      inactiveTrackColor: Colors.grey.shade700,
      thumbColor: AppColors.primaryGreen,
      overlayColor: AppColors.primaryGreen.withOpacity(0.2),
      valueIndicatorColor: AppColors.primaryGreen,
    ),
    
    // BottomNavigationBar Theme (Dark mode)
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _baseTextTheme.labelSmall,
    ),
    
    // Divider Theme (Dark mode)
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 0.5,
      space: 1,
    ),
    
    // Text Theme (Dark mode)
    textTheme: _baseTextTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    
    // Icon Theme (Dark mode)
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
      size: 24,
    ),
    
    // Primary Icon Theme (Dark mode)
    primaryIconTheme: const IconThemeData(
      color: Colors.black,
      size: 24,
    ),
  );
  
  // Animasyon Easing Curves (Apple benzeri)
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve spring = Curves.elasticOut;
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}