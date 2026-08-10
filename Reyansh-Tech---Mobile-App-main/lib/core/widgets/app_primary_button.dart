import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// A full-width primary button used across all screens.
///
/// Usage:
/// ```dart
/// AppPrimaryButton(label: 'Continue', onPressed: _onContinue)
/// AppPrimaryButton(label: 'Pairing...', onPressed: null) // disabled
/// ```
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    return SizedBox(
      width: double.infinity,
      height: dim.shortestSide * 0.13,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.primaryBackground,
          disabledBackgroundColor: AppColors.textPrimary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonLabel(context)),
      ),
    );
  }
}
