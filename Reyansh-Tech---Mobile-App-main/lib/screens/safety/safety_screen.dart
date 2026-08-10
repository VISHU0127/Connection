import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'models/driving_behavior.dart';
import 'models/safety_alert.dart';
import 'widgets/safety_score_card.dart';
import 'widgets/driving_behavior_section.dart';
import 'widgets/safety_recent_alerts.dart';
import 'widgets/safety_tips_section.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const behaviors = [
      DrivingBehavior(
        title: 'Speed Control',
        ratingLabel: 'Excellent',
        score: 95,
        rating: BehaviorRating.excellent,
      ),
      DrivingBehavior(
        title: 'Breaking',
        ratingLabel: 'Good',
        score: 88,
        rating: BehaviorRating.good,
      ),
      DrivingBehavior(
        title: 'Accelerations',
        ratingLabel: 'Needs improvements',
        score: 72,
        rating: BehaviorRating.needsImprovement,
      ),
    ];

    const alerts = [
      SafetyAlert(
        title: 'Harsh Braking Detected',
        time: '8:30 AM',
        miles: '12.3 miles',
        duration: '25 mins',
      ),
    ];

    const tips = [
      'Avoid sudden acceleration to improve your safety score',
      'Avoid sudden acceleration to improve your safety score',
      'Avoid sudden acceleration to improve your safety score',
    ];

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              const AppHeader(
                title: 'Safety Score',
                subtitle: 'AI-powered driving behavior analysis',
              ),

              const SizedBox(height: AppSpacing.lg),

              /// 🏆 Score Card
              const SafetyScoreCard(score: 92, pointsThisWeek: 5),

              const SizedBox(height: AppSpacing.xl),

              /// 🚗 Driving Behavior
              const DrivingBehaviorSection(behaviors: behaviors),

              const SizedBox(height: AppSpacing.xl),

              /// 🔔 Recent Alerts
              SafetyRecentAlerts(
                alerts: alerts,
                onViewAll: () {},
              ),

              const SizedBox(height: AppSpacing.xl),

              /// 💡 Safety Tips
              const SafetyTipsSection(tips: tips),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}