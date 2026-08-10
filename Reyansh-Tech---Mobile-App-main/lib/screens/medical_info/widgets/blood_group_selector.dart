import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';

class BloodGroupSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  static const _groups = ['A+', 'B+', 'AB+', 'AB-', 'A-', 'B-', 'O+', 'O-'];

  const BloodGroupSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final tileSize = dim.shortestSide * 0.17;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Blood Group', style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm + 2,
          runSpacing: AppSpacing.sm + 2,
          children: _groups.map((group) {
            final isSelected = group == selected;
            return GestureDetector(
              onTap: () => onSelected(group),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppColors.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.borderColor,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  group,
                  style: AppTextStyles.body(context).copyWith(
                    color: isSelected ? AppColors.primaryBackground : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}