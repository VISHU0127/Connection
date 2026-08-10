import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppIconBox
///
/// A square rounded container with a coloured tint background and an icon.
/// Used everywhere an icon needs to sit inside a coloured tile:
///   - AlertCard, QuickActionsGrid, RecentActivityList,
///     TodaysTrips, SafetyRecentAlerts
///
/// [icon]        — the icon to display
/// [iconColor]   — icon foreground colour
/// [bgColor]     — tint colour; the box fills with bgColor.withOpacity(0.15)
/// [sizeFactor]  — fraction of shortestSide (default 0.10)
/// [radius]      — corner radius (default AppSpacing.sm)
/// ─────────────────────────────────────────────────────────────────────────────
class AppIconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double sizeFactor;
  final double? radius;

  const AppIconBox({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.sizeFactor = 0.10,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final boxSize = dim.shortestSide * sizeFactor;
    final iconSize = boxSize * 0.50;
    final cornerRadius = radius ?? AppSpacing.sm.toDouble();

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}
