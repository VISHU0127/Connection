import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppStatusBadge
///
/// Inline coloured text label used to show severity / status.
/// Currently used in: AlertCard, SafetyRecentAlerts
///
/// [label] — text to display ("Warning", "Danger", "Info", "Connected", …)
/// [color] — text colour (and optional background tint when [filled] is true)
/// [filled]— when true, wraps text in a tinted pill container
/// ─────────────────────────────────────────────────────────────────────────────
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.small(context).copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );

    if (!filled) return text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: text,
    );
  }
}
