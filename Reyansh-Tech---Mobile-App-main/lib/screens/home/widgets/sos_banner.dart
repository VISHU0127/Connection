import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';

class SosBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const SosBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final iconContainerSize = dim.shortestSide * 0.13;
    final iconSize = iconContainerSize * 0.46;
    final chevronSize = dim.shortestSide * 0.065;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.sosGradientStart, AppColors.sosGradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.xl),
        ),
        child: Row(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone,
                color: AppColors.primaryBackground,
                size: iconSize,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: AppTextStyles.title(context)
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap to call for help',
                    style: AppTextStyles.small(context).copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
              size: chevronSize,
            ),
          ],
        ),
      ),
    );
  }
}