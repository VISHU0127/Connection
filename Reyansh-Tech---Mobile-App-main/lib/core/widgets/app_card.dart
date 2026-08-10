import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppCard — single source of truth for every card surface in the app.
///
/// All card widgets (AlertCard, BehaviorCard, VehicleCard, etc.) use this as
/// their outermost shell. Changing colour, radius, shadow or border here
/// updates every card in the project at once.
///
/// Parameters
/// ──────────
/// [child]   — content inside the card
/// [padding] — defaults to EdgeInsets.all(AppSpacing.md)
/// [color]   — defaults to AppColors.panelColor
/// [radius]  — corner radius; defaults to AppSpacing.md (12)
/// [border]  — optional Border (e.g. accent highlight)
/// [onTap]   — wraps the card in InkWell when provided
/// ─────────────────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? radius;
  final Border? border;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? AppSpacing.md.toDouble();
    final decoration = BoxDecoration(
      color: color ?? AppColors.panelColor,
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: border,
    );

    final container = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return container;

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: container,
        ),
      ),
    );
  }
}
