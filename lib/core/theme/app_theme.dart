import 'package:flutter/material.dart';

/// Okabe-Ito color-blind-safe palette.
/// https://jfly.uni-koeln.de/color/
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0072B2); // Blue
  static const Color secondary = Color(0xFFE69F00); // Orange (CTA)
  static const Color error = Color(0xFFD55E00); // Vermilion
  static const Color success = Color(0xFF009E73); // Bluish Green
  static const Color warning = Color(0xFFF0E442); // Yellow

  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFAFAFA);
  static const Color onSurface = Color(0xFF111111);
  static const Color outline = Color(0xFFBDBDBD);
}

/// Standard corner radii / spacing so screens stop hand-rolling values.
abstract final class AppRadii {
  static const double small = 10;
  static const double medium = 14;
  static const double large = 20;
  static const double pill = 999;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Theme-aware color shortcuts. Widgets must use these (or [ColorScheme])
/// instead of hardcoded greys so dark mode renders correctly.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Main text/icon color on the current surface.
  Color get textPrimary => colors.onSurface;

  /// Secondary text (was Colors.black54).
  Color get textSecondary => colors.onSurface.withValues(alpha: 0.6);

  /// Faint text/icons/dividers (was Colors.black26/38/45).
  Color get textFaint => colors.onSurface.withValues(alpha: 0.4);

  /// Raised container fill (was AppColors.surface).
  Color get surfaceAlt => colors.surfaceContainerHighest;

  /// Hairline borders (was AppColors.outline).
  Color get hairline => colors.outline;

  /// Scaffold/page background.
  Color get pageBackground => Theme.of(this).scaffoldBackgroundColor;
}

/// Brand typography — Plus Jakarta Sans (bundled, latin subset covers EN/ID).
const String _fontFamily = 'PlusJakartaSans';

TextTheme _textTheme(Color onSurface) {
  final base = Typography.material2021()
      .black
      .apply(bodyColor: onSurface, displayColor: onSurface);
  return base
      .copyWith(
        displaySmall: base.displaySmall
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: base.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(height: 1.35),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.35),
        bodySmall: base.bodySmall?.copyWith(height: 1.3),
      )
      .apply(fontFamily: _fontFamily);
}

ThemeData _baseTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Okabe-Ito derived pairs: sky blue / vermillion / green are lightened on
  // dark backgrounds so contrast stays readable; orange is identical on both.
  final primary = isDark ? const Color(0xFF56B4E9) : AppColors.primary;
  final secondary = AppColors.secondary;
  final error = isDark ? const Color(0xFFF0824D) : AppColors.error;
  final success = isDark ? const Color(0xFF2EBD8B) : AppColors.success;
  final background =
      isDark ? const Color(0xFF0E1116) : AppColors.background;
  final surface = isDark ? const Color(0xFF161B22) : AppColors.surface;
  final surfaceHigh = isDark ? const Color(0xFF1F2630) : AppColors.surface;
  final onSurface = isDark ? const Color(0xFFE6E8EA) : AppColors.onSurface;
  final outline = isDark ? const Color(0xFF39414D) : AppColors.outline;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: isDark ? const Color(0xFF06263A) : Colors.white,
    secondary: secondary,
    onSecondary: const Color(0xFF111111),
    tertiary: success,
    onTertiary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: background,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceHigh,
    outline: outline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _textTheme(onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium - 2),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: isDark ? const Color(0xFF06263A) : Colors.white,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium - 2),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh.withValues(alpha: isDark ? 1 : 0.55),
      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.45)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium - 2),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium - 2),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium - 2),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: outline.withValues(alpha: 0.7)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceHigh,
      side: BorderSide(color: outline.withValues(alpha: 0.6)),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.large)),
      ),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      iconColor: onSurface.withValues(alpha: 0.7),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: secondary,
      linearTrackColor: outline.withValues(alpha: 0.3),
    ),
    dividerTheme: DividerThemeData(color: outline.withValues(alpha: 0.4)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium - 2),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _baseTheme(Brightness.light);

  /// Dark variant derived from the same Okabe-Ito roles (sky-blue primary,
  /// unchanged orange CTA) on deep blue-grey surfaces.
  static ThemeData dark() => _baseTheme(Brightness.dark);
}
