import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// Reusable logo + tagline header used on Splash and Landing screens.
class AppLogoHeader extends StatelessWidget {
  final bool expanded;

  const AppLogoHeader({super.key, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: dim.logoHeight,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'EMERGENCY RESPONSE SYSTEM',
          textAlign: TextAlign.center,
          style: AppTextStyles.splashSubtitle(context),
        ),
      ],
    );

    if (expanded) return Expanded(child: content);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: content,
    );
  }
}
