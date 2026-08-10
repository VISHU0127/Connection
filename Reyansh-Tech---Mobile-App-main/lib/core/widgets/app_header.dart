import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showLogo;
  final bool expanded;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showLogo = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Center(child: Image.asset('assets/images/logo.png', height: dim.logoHeight)),
          SizedBox(height: AppSpacing.sm),
        ],
        if (title != null)
          Text(
            title!,
            style: AppTextStyles.heading(context),
          ),
        if (subtitle != null) SizedBox(height: dim.shortestSide * 0.012),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTextStyles.subtitle(context),
          ),
      ],
    );

    if (expanded) return Expanded(child: content);

    return content;
  }
}