import 'package:flutter/material.dart';

/// Design tokens for the "premium career-tech platform" visual direction —
/// deep olive + navy + a restrained brass accent, on a warm neutral ground.
///
/// [brass] is deliberately NOT part of the [ColorScheme] passed to
/// [ThemeData] — measured against WCAG 2.2 AA, brass text on either
/// [offWhite] (2.86:1) or [cardWhite] (3.09:1) falls well short of the
/// 4.5:1 normal-text minimum. Material's ColorScheme roles (e.g.
/// `tertiary`) get applied to text automatically in places (chips, some
/// button variants), so putting brass there would silently produce
/// unreadable text throughout the app. Brass stays a standalone token,
/// used deliberately only where contrast has been checked: as an icon
/// tint or a badge *background* paired with [charcoal] text (5.04:1,
/// passes), or as text on [navyDeep] (4.70:1, passes).
class AppColors {
  AppColors._();

  static const Color oliveDeep = Color(0xFF34452F);
  static const Color navyDeep = Color(0xFF182B3A);
  static const Color brass = Color(0xFFB08D57);

  /// A darkened, more saturated brass — unlike [brass] itself, this passes
  /// WCAG 2.2 AA as text on [offWhite] (4.63:1) and [cardWhite] (5.01:1),
  /// so it's safe where brass's warm identity is wanted but the surface is
  /// actual text, not just an icon tint or a badge background.
  static const Color brassDeep = Color(0xFF8A6A34);
  static const Color offWhite = Color(0xFFF7F6F2);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF202522);
  static const Color slateGrey = Color(0xFF66706A);

  static const Color success = Color(0xFF2E7D4F);
  static const Color warning = Color(0xFFB8600A);
  static const Color error = Color(0xFFB3261E);
  static const Color info = Color(0xFF2E5F8A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.oliveDeep,
      onPrimary: Colors.white,
      secondary: AppColors.navyDeep,
      onSecondary: Colors.white,
      // Material applies `tertiary` to some component text (e.g. certain
      // chip/segmented-button states) — brass fails contrast as text on
      // light surfaces, so tertiary stays a second olive/navy-family tone
      // rather than brass. Use AppColors.brass directly, deliberately,
      // wherever it's actually safe (see the class doc above).
      tertiary: AppColors.navyDeep,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.cardWhite,
      onSurface: AppColors.charcoal,
      onSurfaceVariant: AppColors.slateGrey,
      surfaceContainerHighest: Color(0xFFEDEBE4),
      outline: Color(0xFFC9C6BC),
      outlineVariant: Color(0xFFDEDCD3),
    );

    const baseTextTheme = Typography.blackMountainView;
    final textTheme = baseTextTheme.copyWith(
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: AppColors.charcoal,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.charcoal,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.charcoal,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, color: AppColors.charcoal),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16, color: AppColors.charcoal),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 14, color: AppColors.slateGrey),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.offWhite,
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFDEDCD3)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: Color(0xFFC9C6BC)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        indicatorColor: AppColors.oliveDeep.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.oliveDeep : AppColors.slateGrey,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedIconTheme: IconThemeData(color: AppColors.oliveDeep),
        selectedLabelTextStyle: TextStyle(color: AppColors.oliveDeep, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: AppColors.slateGrey),
      ),
    );
  }
}
