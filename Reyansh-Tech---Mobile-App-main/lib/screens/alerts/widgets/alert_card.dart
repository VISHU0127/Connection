import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_icon_box.dart';
import 'package:my_app/core/widgets/app_status_badge.dart';
import '../models/alert_item.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;

  const AlertCard({super.key, required this.alert});

  Color _severityColor(BuildContext context) {
    switch (alert.severity) {
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.danger:
        return AppColors.danger;
      case AlertSeverity.info:
        return AppColors.success;
    }
  }

  String get _severityLabel {
    switch (alert.severity) {
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.danger:
        return 'Danger';
      case AlertSeverity.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(
            icon: Icons.warning_amber_outlined,
            iconColor: color,
            bgColor: color,
            sizeFactor: 0.11,
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  alert.description,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  alert.time,
                  style: AppTextStyles.captionMuted(context),
                ),
              ],
            ),
          ),
          AppStatusBadge(label: _severityLabel, color: color),
        ],
      ),
    );
  }
}