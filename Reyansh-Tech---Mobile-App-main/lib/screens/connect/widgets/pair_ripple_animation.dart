import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';

class PairAnimation extends StatelessWidget {
  final Animation<double> pulseAnimation1;
  final Animation<double> pulseAnimation2;
  final Animation<double> fadeAnimation1;
  final Animation<double> fadeAnimation2;
  final Listenable listenable;
  final bool isPairing;

  const PairAnimation({
    super.key,
    required this.pulseAnimation1,
    required this.pulseAnimation2,
    required this.fadeAnimation1,
    required this.fadeAnimation2,
    required this.listenable,
    required this.isPairing,
  });

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.shortestSide;
    final boxSize    = s * 0.72;
    final outerSize  = s * 0.53;
    final middleSize = s * 0.48;
    final innerSize  = s * 0.36;
    final loaderSize = s * 0.09;
    final iconSize   = s * 0.10;

    return Expanded(
      child: Center(
        child: SizedBox(
          width: boxSize,
          height: boxSize,
          child: AnimatedBuilder(
            animation: listenable,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  /// Outer ripple 2 (staggered)
                  Transform.scale(
                    scale: pulseAnimation2.value,
                    child: Container(
                      width: outerSize,
                      height: outerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.sosGradientStart.withValues(alpha: fadeAnimation2.value * 0.7),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                  /// Outer ripple 1
                  Transform.scale(
                    scale: pulseAnimation1.value,
                    child: Container(
                      width: outerSize,
                      height: outerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.sosGradientStart.withValues(alpha: fadeAnimation1.value * 0.7),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                  /// Middle static ring
                  Container(
                    width: middleSize,
                    height: middleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sosGradientStart.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),

                  /// Inner circle with icon/loader
                  Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sosGradientStart, width: 2.0),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: isPairing
                          ? SizedBox(
                              width: loaderSize,
                              height: loaderSize,
                              child: CircularProgressIndicator(
                                color: AppColors.textPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.loop_rounded,
                              color: AppColors.textPrimary,
                              size: iconSize,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
