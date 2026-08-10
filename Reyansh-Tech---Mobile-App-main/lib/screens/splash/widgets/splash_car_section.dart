import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';

class SplashCarSection extends StatelessWidget {
  const SplashCarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);

    return Container(
      height: dim.carHeight,
      width: dim.width,
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        "assets/images/car.png",
        fit: BoxFit.contain,
      ),
    );
  }
}
