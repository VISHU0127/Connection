import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppSecondaryButton
///
/// A surface-coloured tappable button. Used wherever an action is needed but
/// does not warrant the full-width primary style — e.g. card action rows,
/// inline "Add" / "Disconnect" / "Pause" controls.
///
/// [label]     — button text
/// [onTap]     — tap callback (null = disabled, rendered at 50 % opacity)
/// [icon]      — optional leading icon
/// [fullWidth] — stretches to parent width when true (default false)
/// ─────────────────────────────────────────────────────────────────────────────
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: disabled
                ? AppColors.textMuted
                : AppColors.textPrimary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            color: disabled ? AppColors.textMuted : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
