import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';

class SafetyScoreCard extends StatelessWidget {
  final int score;
  final int pointsThisWeek;

  const SafetyScoreCard({
    super.key,
    required this.score,
    required this.pointsThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Safety Score',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: AppTextStyles.heading(context).copyWith(
                        color: AppColors.success,
                        fontSize: dim.shortestSide * 0.11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / 100',
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '+$pointsThisWeek points this week',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark circle
          Container(
            width: dim.shortestSide * 0.14,
            height: dim.shortestSide * 0.14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2.5),
            ),
            child: Icon(
              Icons.check,
              color: AppColors.success,
              size: dim.shortestSide * 0.07,
            ),
          ),
        ],
      ),
    );
  }
}