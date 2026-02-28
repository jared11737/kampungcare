import 'package:flutter/material.dart';

class KampungCareTheme {
  // Primary colors — high contrast, warm
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF9A825);
  static const Color urgentRed = Color(0xFFC62828);
  static const Color calmBlue = Color(0xFF1565C0);
  static const Color warmWhite = Color(0xFFFFF8E1);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textOnDark = Color(0xFFFFFDE7);

  // Surface colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFBF0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        surface: warmWhite,
        primary: primaryGreen,
        error: urgentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: textOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textOnDark,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, height: 1.6),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, height: 1.6),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, height: 1.6),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, height: 1.6),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, height: 1.6),
        titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, height: 1.6),
        bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: textPrimary, height: 1.6, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: textPrimary, height: 1.6, letterSpacing: 0.5),
        bodySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: textSecondary, height: 1.6, letterSpacing: 0.5),
        labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textOnDark, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(150, 64),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textSecondary),
        ),
        labelStyle: const TextStyle(fontSize: 20, color: textSecondary),
        hintStyle: const TextStyle(fontSize: 20, color: textSecondary),
      ),
    );
  }
}
