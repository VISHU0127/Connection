import 'package:flutter/material.dart';

class QuickAction {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });
}