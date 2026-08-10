import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// A globally reusable bottom navigation bar.
///
/// Usage:
/// ```dart
/// AppNavBar(
///   currentIndex: _navIndex,
///   onTap: (i) => setState(() => _navIndex = i),
///   items: const [
///     AppNavBarItem(icon: Icons.home_outlined, label: 'Home'),
///     AppNavBarItem(icon: Icons.person_outline, label: 'Profile'),
///   ],
/// )
/// ```
class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavBarItem> items;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final iconSize = dim.shortestSide * 0.06;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.panelColor,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == currentIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  size: iconSize,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  style: AppTextStyles.caption(context).copyWith(
                    color:
                        isActive ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class AppNavBarItem {
  final IconData icon;
  final String label;
  const AppNavBarItem({required this.icon, required this.label});
}
