import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final iconSize = dim.shortestSide * 0.05;

    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.show_chart, color: AppColors.success, size: iconSize),
            SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.heading(context)),
            SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.caption(context)),
          ],
        ),
      ),
    );
  }
}