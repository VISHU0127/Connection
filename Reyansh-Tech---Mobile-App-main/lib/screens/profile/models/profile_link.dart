import 'package:flutter/material.dart';

class ProfileLink {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const ProfileLink({
    required this.label,
    required this.icon,
    this.onTap,
  });
}