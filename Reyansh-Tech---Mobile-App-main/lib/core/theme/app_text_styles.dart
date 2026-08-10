import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// All text styles in the app live here.
/// Use these — never set fontSize inline in any widget.
///
/// Scale:
///   heading  → screen titles  ("Welcome", "Pair Device")
///   title    → section titles
///   body     → input text, card content
///   label    → input field labels, selectors
///   small    → secondary info
///   caption  → terms text, resend, helper hints
class AppTextStyles {
  // ── Headings ──────────────────────────────────────────────
  static TextStyle heading(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: dim.fontSizeHeading,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );
  }

  static TextStyle title(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: dim.fontSizeTitle,
      fontWeight: FontWeight.bold,
      letterSpacing: dim.letterSpacingWide,
    );
  }

  // ── Subtitle / screen description ─────────────────────────
  static TextStyle subtitle(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: dim.fontSizeBody,
    );
  }

  // ── Body ──────────────────────────────────────────────────
  static TextStyle body(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: dim.fontSizeBody,
    );
  }

  static TextStyle bodyMuted(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textMuted,
      fontSize: dim.fontSizeBody,
    );
  }

  // ── Input labels ──────────────────────────────────────────
  static TextStyle label(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: dim.fontSizeLabel,
      fontWeight: FontWeight.w500,
    );
  }

  // ── Small / secondary info ────────────────────────────────
  static TextStyle small(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: dim.fontSizeSmall,
    );
  }

  // ── Caption — terms, resend, hints ────────────────────────
  static TextStyle caption(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: dim.fontSizeCaption,
    );
  }

  static TextStyle captionMuted(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textMuted,
      fontSize: dim.fontSizeCaption,
    );
  }

  // ── Splash ────────────────────────────────────────────────
  static TextStyle buttonLabel(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      fontSize: dim.fontSizeBodyLarge,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: dim.fontSizeBodyLarge,
    );
  }

  static TextStyle splashSubtitle(BuildContext context) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: AppColors.textSecondary,
      fontSize: dim.fontSizeSmall,
      letterSpacing: dim.letterSpacingNormal,
    );
  }

  // ── Screen title (alias for landing/splash) ───────────────
  static TextStyle screenTitle(BuildContext context) => title(context);

  // ── Body small (alias) ────────────────────────────────────
  static TextStyle bodySmall(BuildContext context) => small(context);

  // ── IoT device status ─────────────────────────────────────
  static TextStyle deviceStatus(BuildContext context, Color statusColor) {
    final dim = AppDimensions(context);
    return TextStyle(
      color: statusColor,
      fontSize: dim.fontSizeSmall,
      fontWeight: FontWeight.w600,
      letterSpacing: dim.letterSpacingNormal,
    );
  }
}
