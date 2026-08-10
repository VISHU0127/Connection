import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppProgressBar
///
/// Single source of truth for every progress / score bar in the app.
/// Changing height, radius, or background colour here updates all bars at once.
///
/// [value]   — 0.0 → 1.0
/// [color]   — filled bar colour
/// [height]  — bar thickness (default 6)
/// ─────────────────────────────────────────────────────────────────────────────
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs.toDouble()),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.dividerColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
