import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'models/alert_item.dart';
import 'widgets/alerts_stats_row.dart';
import 'widgets/recent_alerts_list.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late List<AlertItem> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = [
      AlertItem(
        title: 'Harsh Braking Detected',
        description: 'Sudden braking detected on Highway 101',
        time: '2 Hours Ago',
        severity: AlertSeverity.warning,
      ),
      AlertItem(
        title: 'Harsh Braking Detected',
        description: 'Sudden braking detected on Highway 101',
        time: '2 Hours Ago',
        severity: AlertSeverity.warning,
      ),
    ];
  }

  void _markAllRead() {
    setState(() {
      for (final alert in _alerts) {
        alert.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              const AppHeader(
                title: 'Alerts',
                subtitle: 'Stay informed about your driving',
              ),

              const SizedBox(height: AppSpacing.xl),

              /// 📊 Stats
              const AlertsStatsRow(),

              const SizedBox(height: AppSpacing.xl),

              /// 🔔 Recent Alerts
              RecentAlertsList(
                alerts: _alerts,
                onMarkAllRead: _markAllRead,
              ),
            ],
          ),
        ),
      ),
    );
  }
}