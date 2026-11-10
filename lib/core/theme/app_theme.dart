import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondaryColor = Color(0xFFD97706); // Construction Amber
  static const Color successColor = Color(0xFF059669); // Emerald Cash
  static const Color infoColor = Color(0xFF2563EB); // Online UPI Blue
  static const Color warningColor = Color(0xFFD97706); // Amber
  static const Color dangerColor = Color(0xFFDC2626); // Crimson Udhaar
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);

  static ThemeData lightTheme(double fontMultiplier) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      fontFamily: 'Segoe UI',
    );

    return _applyFontScaling(base, fontMultiplier);
  }

  static ThemeData darkTheme(double fontMultiplier) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(0xFF3B82F6),
        secondary: secondaryColor,
        error: dangerColor,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      fontFamily: 'Segoe UI',
    );

    return _applyFontScaling(base, fontMultiplier);
  }

  static ThemeData _applyFontScaling(ThemeData base, double multiplier) {
    final textTheme = base.textTheme;

    TextStyle scale(TextStyle? style) {
      if (style == null) return const TextStyle();
      return style.copyWith(
        fontSize: (style.fontSize ?? 14.0) * multiplier,
      );
    }

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: scale(textTheme.displayLarge),
        displayMedium: scale(textTheme.displayMedium),
        displaySmall: scale(textTheme.displaySmall),
        headlineLarge: scale(textTheme.headlineLarge),
        headlineMedium: scale(textTheme.headlineMedium),
        headlineSmall: scale(textTheme.headlineSmall),
        titleLarge: scale(textTheme.titleLarge),
        titleMedium: scale(textTheme.titleMedium),
        titleSmall: scale(textTheme.titleSmall),
        bodyLarge: scale(textTheme.bodyLarge),
        bodyMedium: scale(textTheme.bodyMedium),
        bodySmall: scale(textTheme.bodySmall),
        labelLarge: scale(textTheme.labelLarge),
        labelMedium: scale(textTheme.labelMedium),
        labelSmall: scale(textTheme.labelSmall),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: base.brightness == Brightness.light
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF1E293B),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: base.brightness == Brightness.light
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF334155),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: base.brightness == Brightness.light
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF334155),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }
}
