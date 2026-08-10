import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_stat_card.dart';

class AlertsStatsRow extends StatelessWidget {
  const AlertsStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppStatCard(
          icon: Icons.warning_amber_outlined,
          value: '3',
          label: 'Warnings',
        ),
        const SizedBox(width: AppSpacing.sm),
        AppStatCard(
          icon: Icons.check_circle_outline,
          value: '32',
          label: 'Safe Trips',
        ),
        const SizedBox(width: AppSpacing.sm),
        AppStatCard(
          icon: Icons.route_outlined,
          value: '125',
          label: 'Miles',
        ),
      ],
    );
  }
}