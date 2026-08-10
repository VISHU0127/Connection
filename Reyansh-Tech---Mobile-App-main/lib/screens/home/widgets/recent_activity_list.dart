import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_icon_box.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import '../models/recent_activity.dart';

class RecentActivityList extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Recent Activity'),
        SizedBox(height: AppSpacing.sm + 2),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  AppIconBox(
                    icon: activity.icon,
                    iconColor: activity.iconColor,
                    bgColor: activity.bgColor,
                    sizeFactor: 0.105,
                    radius: AppSpacing.md.toDouble(),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: AppTextStyles.body(context)
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          activity.time,
                          style: AppTextStyles.captionMuted(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}