import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant, rich non-pale colors
  static const Color primaryNavy = Color(0xFF0F2744); // Deep Navy Slate
  static const Color primaryColor = Color(0xFF1E3A8A); // Royal Business Blue
  static const Color successGreen = Color(0xFF15803D); // Rich Forest Green (Cash & Growth)
  static const Color dangerRed = Color(0xFFB91C1C); // Strong Crimson (Udhaar & Alerts)
  static const Color warningAmber = Color(0xFFD97706); // Rich Golden Amber (Highlights & Warnings)
  static const Color accentGold = Color(0xFFB45309);
  
  // Surfaces
  static const Color backgroundLight = Color(0xFFF4F6F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFCBD5E1);
  static const Color darkSlate = Color(0xFF0F172A);

  // Aliases for compatibility
  static const Color successColor = successGreen;
  static const Color dangerColor = dangerRed;
  static const Color warningColor = warningAmber;
  static const Color secondaryColor = warningAmber;
  static const Color infoColor = Color(0xFF2563EB);

  static ThemeData lightTheme(double fontMultiplier) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: Brightness.light,
        primary: primaryNavy,
        secondary: warningAmber,
        error: dangerRed,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['NotoSansDevanagari', 'Roboto', 'Arial'],
    );

    return _applyFontScaling(base, fontMultiplier);
  }

  static ThemeData darkTheme(double fontMultiplier) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        brightness: Brightness.dark,
        primary: const Color(0xFF3B82F6),
        secondary: warningAmber,
        error: dangerRed,
        surface: darkSlate,
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
        elevation: 1,
        color: base.brightness == Brightness.light ? surfaceWhite : const Color(0xFF1E293B),
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: base.brightness == Brightness.light
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF334155),
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
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
