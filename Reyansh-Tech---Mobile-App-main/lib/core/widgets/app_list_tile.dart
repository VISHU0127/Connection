import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';
import '../constants/app_spacing.dart';
import 'app_card.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppListTile
///
/// Tappable row with a leading icon, title, and a trailing chevron.
/// Replaces ProfileLinkTile and any other custom chevron-row widgets.
///
/// [icon]          — leading icon
/// [label]         — row text
/// [onTap]         — tap callback
/// [isDestructive] — renders icon + text in AppColors.danger when true
/// [trailing]      — override trailing widget (default: chevron_right)
/// ─────────────────────────────────────────────────────────────────────────────
class AppListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;

  const AppListTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final iconSize = dim.shortestSide * 0.055;
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(context).copyWith(
                color: color,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: iconSize),
        ],
      ),
    );
  }
}
