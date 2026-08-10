import 'package:flutter/material.dart';

class ConnectRippleAnimation extends StatelessWidget {
  const ConnectRippleAnimation({
    super.key,
    required this.entryAnim,
    required this.pulseController1,
    required this.pulseController2,
    required this.scaleAnim1,
    required this.fadeAnim1,
    required this.scaleAnim2,
    required this.fadeAnim2,
    required this.checkController,
    required this.checkAnim,
  });

  final Animation<double> entryAnim;
  final AnimationController pulseController1;
  final AnimationController pulseController2;
  final Animation<double> scaleAnim1;
  final Animation<double> fadeAnim1;
  final Animation<double> scaleAnim2;
  final Animation<double> fadeAnim2;
  final AnimationController checkController;
  final Animation<double> checkAnim;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF3DDC6A);
    const dimGreen = Color(0xFF1A6632);
    final s = MediaQuery.of(context).size.shortestSide;
    final boxSize   = s * 0.72;
    final rippleSize = s * 0.50;
    final innerSize  = s * 0.37;
    final checkSize  = s * 0.11;

    return Expanded(
      child: Center(
        child: ScaleTransition(
          scale: entryAnim,
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                pulseController1,
                pulseController2,
                checkController,
              ]),
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple ring 1
                    Transform.scale(
                      scale: scaleAnim1.value,
                      child: Container(
                        width: rippleSize,
                        height: rippleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: green.withValues(alpha: fadeAnim1.value * 0.45),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Ripple ring 2 (staggered)
                    Transform.scale(
                      scale: scaleAnim2.value,
                      child: Container(
                        width: rippleSize,
                        height: rippleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: green.withValues(alpha: fadeAnim2.value * 0.45),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Middle faint static ring
                    Container(
                      width: rippleSize,
                      height: rippleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dimGreen.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                    ),

                    // Inner green border circle with checkmark
                    Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: green,
                          width: 2.0,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: Size(checkSize, checkSize),
                          painter: CheckmarkPainter(
                            progress: checkAnim.value,
                            color: green,
                            strokeWidth: 3.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  const CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * 0.18, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.74);
    final p3 = Offset(size.width * 0.82, size.height * 0.28);

    const seg1Fraction = 0.38;
    const seg2Fraction = 1.0 - seg1Fraction;

    final path = Path();

    if (progress <= seg1Fraction) {
      final t = progress / seg1Fraction;
      final mid = Offset.lerp(p1, p2, t)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(mid.dx, mid.dy);
    } else {
      final t = (progress - seg1Fraction) / seg2Fraction;
      final mid = Offset.lerp(p2, p3, t)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(mid.dx, mid.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter old) => old.progress != progress;
}
