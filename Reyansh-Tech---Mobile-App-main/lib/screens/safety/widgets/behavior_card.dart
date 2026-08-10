import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_progress_bar.dart';
import '../models/driving_behavior.dart';

class BehaviorCard extends StatelessWidget {
  final DrivingBehavior behavior;

  const BehaviorCard({super.key, required this.behavior});

  Color get _scoreColor {
    switch (behavior.rating) {
      case BehaviorRating.excellent:
        return AppColors.success;
      case BehaviorRating.good:
        return AppColors.success;
      case BehaviorRating.needsImprovement:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    behavior.title,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    behavior.ratingLabel,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '${behavior.score}',
                style: AppTextStyles.heading(context).copyWith(
                  color: _scoreColor,
                  fontSize: dim.shortestSide * 0.056,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(value: behavior.score / 100, color: _scoreColor),
        ],
      ),
    );
  }
}