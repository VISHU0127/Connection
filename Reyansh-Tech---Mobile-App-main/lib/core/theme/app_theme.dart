import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ── Convenience re-exports ────────────────────────────────
  static const Color primaryBackground = AppColors.primaryBackground;
  static const Color subtitleColor = AppColors.textSecondary;

  // ── Gradient ─────────────────────────────────────────────
  static BoxDecoration splashBackground = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-1.0, -1.0),
      radius: 0.9,
      colors: [
        AppColors.textSecondary.withValues(alpha: 0.2),
        AppColors.primaryBackground,
      ],
    ),
  );

  static BoxDecoration screenBackground = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(-1.0, -1.0),
      radius: 0.9,
      colors: [
        AppColors.accent.withValues(alpha: 0.2),
        AppColors.primaryBackground,
      ],
    ),
  );

  // ── Material Theme ────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.primaryBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surfaceColor,
      error: AppColors.danger,
    ),
    cardColor: AppColors.cardColor,
    dividerColor: AppColors.dividerColor,
    fontFamily: 'Roboto',
  );
}
