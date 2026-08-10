import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_stat_card.dart';

class TrackingStatsRow extends StatelessWidget {
  const TrackingStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Row(
          children: [
            AppStatCard(
              icon: Icons.local_shipping_outlined,
              value: '48',
              label: 'mph',
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatCard(
              icon: Icons.location_on_outlined,
              value: '128',
              label: 'Miles',
            ),
            const SizedBox(width: AppSpacing.sm),
            AppStatCard(
              icon: Icons.access_time_outlined,
              value: '130',
              label: 'Minutes',
            ),
          ],
        ),
      ],
    );
  }
}