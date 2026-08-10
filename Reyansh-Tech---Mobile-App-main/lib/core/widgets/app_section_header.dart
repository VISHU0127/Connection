import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppSectionHeader
///
/// Consistent section title row used across every screen.
/// Changing font, weight or colour here updates all section headers at once.
///
/// [title]       — required section name ("Recent Alerts", "Quick Actions", …)
/// [actionLabel] — optional right-side link text ("View all", "Mark all read")
/// [onAction]    — callback for the action tap
/// ─────────────────────────────────────────────────────────────────────────────
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.small(context).copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
