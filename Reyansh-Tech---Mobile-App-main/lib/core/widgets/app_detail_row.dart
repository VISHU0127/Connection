import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppDetailRow
///
/// A horizontal label → value row with an optional leading icon.
/// Used in VehicleCard, EmergencyContactCard, PersonalInfo, LiveTrackingCard.
///
/// [label]       — left-side muted text
/// [value]       — right-side primary text
/// [icon]        — optional leading icon
/// [valueColor]  — override for value text colour (default textPrimary)
/// ─────────────────────────────────────────────────────────────────────────────
class AppDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.caption(context).copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
