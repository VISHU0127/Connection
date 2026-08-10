import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_header.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool centerAlign;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.centerAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    final header = AppHeader(
      title: title,
      subtitle: subtitle,
      showLogo: false,
      expanded: false,
    );

    return Column(
      crossAxisAlignment:
          centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        SizedBox(height: dim.shortestSide * 0.10),
        centerAlign ? Center(child: header) : header,
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}