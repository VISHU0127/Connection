import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/constants/app_spacing.dart';

class TrackingMapView extends StatelessWidget {
  const TrackingMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final mapHeight = dim.shortestSide * 0.72;
    final pinSize = dim.shortestSide * 0.10;

    return SizedBox(
      height: mapHeight,
      child: Stack(
        children: [
          // 🗺️ Placeholder dark map background
          Container(
            width: double.infinity,
            height: mapHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceColor,
                  AppColors.primaryBackground,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Grid lines to simulate map feel
          CustomPaint(
            size: Size(double.infinity, mapHeight),
            painter: _MapGridPainter(),
          ),

          // Center pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.sosGradientStart,
                  size: pinSize,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Map loads after API key is set',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}