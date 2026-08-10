import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';

class PolicySection extends StatelessWidget {
  final String heading;
  final List<String> paragraphs;

  const PolicySection({
    super.key,
    required this.heading,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...paragraphs.map((para) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                para,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            )),
      ],
    );
  }
}