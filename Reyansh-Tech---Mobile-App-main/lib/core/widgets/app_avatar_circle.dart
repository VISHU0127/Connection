import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppAvatarCircle
///
/// Circular avatar placeholder used across ProfileUserCard,
/// EmergencyContactCard, and PersonalInfoScreen.
///
/// [icon]        — icon to show (default Icons.person_outline)
/// [iconColor]   — icon colour (default textMuted)
/// [bgColor]     — background fill (default surfaceColor)
/// [sizeFactor]  — fraction of shortestSide (default 0.13)
/// [border]      — optional border
/// ─────────────────────────────────────────────────────────────────────────────
class AppAvatarCircle extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final double sizeFactor;
  final BoxBorder? border;

  const AppAvatarCircle({
    super.key,
    this.icon = Icons.person_outline,
    this.iconColor,
    this.bgColor,
    this.sizeFactor = 0.13,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final size = dim.shortestSide * sizeFactor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor ?? AppColors.surfaceColor,
        border: border,
      ),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.textMuted,
        size: size * 0.50,
      ),
    );
  }
}
