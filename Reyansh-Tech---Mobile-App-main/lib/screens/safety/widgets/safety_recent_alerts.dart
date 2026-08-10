import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_icon_box.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import 'package:my_app/core/widgets/app_status_badge.dart';
import '../models/safety_alert.dart';

class SafetyRecentAlerts extends StatelessWidget {
  final List<SafetyAlert> alerts;
  final VoidCallback onViewAll;

  const SafetyRecentAlerts({
    super.key,
    required this.alerts,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent Alerts',
          actionLabel: 'View all',
          onAction: onViewAll,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Row(
                  children: [
                    AppIconBox(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.warning,
                      bgColor: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                            '${alert.time} • ${alert.miles} • ${alert.duration}',
                            style: AppTextStyles.captionMuted(context),
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: 'Warning',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}