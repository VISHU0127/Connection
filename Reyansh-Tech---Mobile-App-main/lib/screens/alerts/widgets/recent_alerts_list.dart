import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import '../models/alert_item.dart';
import 'alert_card.dart';

class RecentAlertsList extends StatelessWidget {
  final List<AlertItem> alerts;
  final VoidCallback onMarkAllRead;

  const RecentAlertsList({
    super.key,
    required this.alerts,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent Alerts',
          actionLabel: 'Mark all as read',
          onAction: onMarkAllRead,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...alerts.map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlertCard(alert: alert),
            )),
      ],
    );
  }
}