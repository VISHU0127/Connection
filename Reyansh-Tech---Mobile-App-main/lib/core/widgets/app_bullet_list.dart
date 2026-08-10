import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppBulletList
///
/// Renders a list of strings as bullet points in muted caption style.
/// Used inside SafetyTipsSection, VehicleTipsSection, and any future tip cards.
///
/// Wrap in an AppCard + Column with a header Text to match existing usage.
/// ─────────────────────────────────────────────────────────────────────────────
class AppBulletList extends StatelessWidget {
  final List<String> items;

  const AppBulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTextStyles.caption(context)
                        .copyWith(color: AppColors.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
