import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(decoration: AppTheme.splashBackground),
    );
  }
}
