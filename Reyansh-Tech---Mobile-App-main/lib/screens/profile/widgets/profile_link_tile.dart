import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_list_tile.dart';

/// Thin wrapper kept for backward-compat. Delegates entirely to AppListTile.
class ProfileLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const ProfileLinkTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      icon: icon,
      label: label,
      onTap: onTap,
      isDestructive: isDestructive,
    );
  }
}
