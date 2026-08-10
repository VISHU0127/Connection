import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final buttonSize = dim.shortestSide * 0.11;
    final iconSize = dim.shortestSide * 0.055;
    final dotSize = dim.shortestSide * 0.022;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('12 October Monday', style: AppTextStyles.subtitle(context)),
              SizedBox(height: AppSpacing.xs),
              Text('Good Morning! Jhon', style: AppTextStyles.heading(context)),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.panelColor,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: iconSize,
              ),
            ),
            Positioned(
              top: buttonSize * 0.2,
              right: buttonSize * 0.2,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}