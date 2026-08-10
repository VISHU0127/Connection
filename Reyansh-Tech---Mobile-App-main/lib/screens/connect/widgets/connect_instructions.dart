import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';

class ConnectInstructions extends StatelessWidget {
  const ConnectInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Setup Instructions', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          _ConnectStep(number: 1, text: 'Turn on your SafeDrive IoT device'),
          _ConnectStep(number: 2, text: 'Make sure Bluetooth is enabled on your phone'),
          _ConnectStep(
            number: 3,
            text: 'Press the button below to start pairing',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ConnectStep extends StatelessWidget {
  final int number;
  final String text;
  final bool isLast;

  const _ConnectStep({
    required this.number,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final stepCircleSize = dim.shortestSide * 0.07;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: stepCircleSize,
              height: stepCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textMuted, width: 1.5),
              ),
              child: Center(
                child: Text('$number', style: AppTextStyles.small(context).copyWith(fontWeight: FontWeight.w500)),
              ),
            ),
            if (!isLast)
              Container(width: 1, height: AppSpacing.xl, color: AppColors.dividerColor),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: stepCircleSize * 0.15),
            child: Text(text, style: AppTextStyles.small(context).copyWith(height: 1.4)),
          ),
        ),
      ],
    );
  }
}
