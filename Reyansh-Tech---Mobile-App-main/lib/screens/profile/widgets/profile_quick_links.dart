import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import '../models/profile_link.dart';
import 'profile_link_tile.dart';

class ProfileQuickLinks extends StatelessWidget {
  final List<ProfileLink> links;

  const ProfileQuickLinks({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Quick Links'),
        const SizedBox(height: AppSpacing.sm),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ProfileLinkTile(
                icon: link.icon,
                label: link.label,
                onTap: link.onTap,
              ),
            )),
      ],
    );
  }
}