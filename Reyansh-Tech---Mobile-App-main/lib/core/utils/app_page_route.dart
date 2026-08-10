import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A drop-in replacement for [MaterialPageRoute] that keeps the background
/// pure black during push/pop transitions, preventing the grey flash.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder, super.settings});

  @override
  Color? get barrierColor => AppColors.primaryBackground;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
