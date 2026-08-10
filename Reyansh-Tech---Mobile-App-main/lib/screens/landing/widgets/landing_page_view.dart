import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/landing_slide.dart';

class LandingPageView extends StatelessWidget {
  final PageController controller;
  final List<LandingSlide> slides;

  const LandingPageView({
    super.key,
    required this.controller,
    required this.slides,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    return Expanded(
      child: PageView.builder(
        controller: controller,
        itemCount: slides.length,
        itemBuilder: (context, index) {
          final slide = slides[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// 🖼 Slide Image
                Image.asset(
                  slide.imagePath,
                  height: dim.carHeight * 1.1,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: AppSpacing.lg),

                /// 📝 Title
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle(context),
                ),

                const SizedBox(height: AppSpacing.sm),

                /// 💬 Subtitle
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
