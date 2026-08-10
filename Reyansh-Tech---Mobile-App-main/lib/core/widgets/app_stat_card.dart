import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'app_card.dart';

/// Shared stat card used across Home, Tracking, Alerts, etc.
/// Displays an icon, a bold value and a muted label stacked below.
class AppStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const AppStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final iconSize = dim.shortestSide * 0.058;

    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        radius: AppSpacing.sm.toDouble(),
        child: Row(
          children: [
            Icon(icon, color: AppColors.sosGradientStart, size: iconSize),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
