import 'package:flutter/material.dart';

class RecentActivity {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const RecentActivity({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}