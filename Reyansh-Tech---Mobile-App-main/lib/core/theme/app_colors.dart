import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ───────────────────────────────────────────
  static const Color primaryBackground = Colors.black;
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF242424);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color textMuted = Color(0xFF666666);

  // ── Brand / Accent ────────────────────────────────────────
  static const Color accent = Color(0xFFE53935);       // red — emergency
  static const Color accentLight = Color(0xFFEF9A9A);
  static const Color success = Color(0xFF43A047);      // green — device online
  static const Color warning = Color(0xFFFB8C00);      // orange — alert
  static const Color danger = Color(0xFFE53935);       // red — critical

  // ── IoT Device Status ─────────────────────────────────────
  static const Color deviceOnline = success;
  static const Color deviceOffline = textMuted;
  static const Color deviceAlert = warning;
  static const Color deviceCritical = danger;

  // ── Borders / Dividers ────────────────────────────────────
  static const Color borderColor = Color(0xFF2E2E2E);
  static const Color dividerColor = Color(0xFF333333);

  // Panel/card surface used in home screen widgets
  static const Color panelColor = Color(0xFF1C1C1E);

  // SOS banner gradient
  static const Color sosGradientStart = Color(0xFFE8622A);
  static const Color sosGradientEnd   = Color(0xFFD946A8);

  // Quick action icon tints
  static const Color iconBlue = Color(0xFF5B6CF8);
}
