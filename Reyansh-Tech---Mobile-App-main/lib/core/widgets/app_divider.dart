import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppDivider
///
/// Consistent horizontal rule used across every screen.
/// Changing opacity, thickness, or colour here updates all dividers at once.
/// ─────────────────────────────────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.textMuted.withValues(alpha: 0.15),
      thickness: 1,
      height: AppSpacing.lg.toDouble(),
    );
  }
}
