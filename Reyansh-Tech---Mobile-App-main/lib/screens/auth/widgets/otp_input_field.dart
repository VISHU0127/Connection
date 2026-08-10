import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final boxSize = dim.shortestSide * 0.13;

    return GestureDetector(
      // Tap anywhere on the row to (re)open keyboard
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          /// 🔢 6 display boxes
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final digits = value.text.padRight(6);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final filled = i < value.text.length;
                  final isCursor = i == value.text.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: boxSize,
                    height: boxSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      border: Border.all(
                        color: isCursor
                            ? AppColors.textPrimary
                            : AppColors.borderColor,
                        width: isCursor ? 2.0 : 1.0,
                      ),
                    ),
                    child: filled
                        ? Text(
                            digits[i],
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                }),
              );
            },
          ),

          /// 🙈 Invisible TextField — holds focus & keyboard, never visible
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
