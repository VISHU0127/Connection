import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../theme/app_dimensions.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppEmptyState
///
/// Centred empty-state illustration used when a list has no items.
/// Used in: EmergencyContactsScreen, AlertsScreen, VehicleScreen (when empty)
///
/// [icon]     — icon to display (default: Icons.inbox_outlined)
/// [message]  — primary message ("No contacts added yet")
/// [hint]     — optional secondary hint ("Tap + to add one")
/// ─────────────────────────────────────────────────────────────────────────────
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textMuted,
              size: dim.shortestSide * 0.14,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint!,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
