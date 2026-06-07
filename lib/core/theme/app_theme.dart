import 'package:flutter/material.dart';

/// Okabe-Ito color-blind-safe palette.
/// https://jfly.uni-koeln.de/color/
class AppColors {
  AppColors._();

  static const Color primary   = Color(0xFF0072B2); // Blue
  static const Color secondary = Color(0xFFE69F00); // Orange (CTA)
  static const Color error     = Color(0xFFD55E00); // Vermilion
  static const Color success   = Color(0xFF009E73); // Bluish Green
  static const Color warning   = Color(0xFFF0E442); // Yellow

  static const Color background = Colors.white;
  static const Color surface    = Color(0xFFFAFAFA);
  static const Color onSurface  = Color(0xFF111111);
  static const Color outline    = Color(0xFFBDBDBD);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary:        AppColors.primary,
      onPrimary:      Colors.white,
      secondary:      AppColors.secondary,
      onSecondary:    Color(0xFF111111),
      tertiary:       AppColors.success,
      onTertiary:     Colors.white,
      error:          AppColors.error,
      onError:        Colors.white,
      surface:        AppColors.background,
      onSurface:      AppColors.onSurface,
      surfaceContainerHighest: AppColors.surface,
      outline:        AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
