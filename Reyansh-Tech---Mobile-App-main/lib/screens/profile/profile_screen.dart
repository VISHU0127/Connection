import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'models/profile_link.dart';
import 'widgets/profile_user_card.dart';
import 'widgets/profile_quick_links.dart';
import 'widgets/profile_link_tile.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToVehicle;
  final VoidCallback? onNavigateToMedical;
  final VoidCallback? onNavigateToPersonalInfo;
  final VoidCallback? onNavigateToPrivacyPolicy;
  final VoidCallback? onNavigateToEmergencyContacts;

  const ProfileScreen({
    super.key,
    this.onNavigateToVehicle,
    this.onNavigateToMedical,
    this.onNavigateToPersonalInfo,
    this.onNavigateToPrivacyPolicy,
    this.onNavigateToEmergencyContacts,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      ProfileLink(
        label: 'Personal Information',
        icon: Icons.person_outline,
        onTap: () => onNavigateToPersonalInfo?.call(),
      ),
      ProfileLink(
        label: 'Medical Information',
        icon: Icons.favorite_border,
        onTap: () => onNavigateToMedical?.call(),
      ),
      ProfileLink(
        label: 'Vehicle Management',
        icon: Icons.local_shipping_outlined,
        onTap: () => onNavigateToVehicle?.call(),
      ),
      ProfileLink(
        label: 'Privacy Policies',
        icon: Icons.shield_outlined,
        onTap: () => onNavigateToPrivacyPolicy?.call(),
      ),
      ProfileLink(
        label: 'Emergency Contacts',
        icon: Icons.phone_outlined,
        onTap: () => onNavigateToEmergencyContacts?.call(),
      ),
    ];

    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              const AppHeader(
                title: 'My Profile',
                subtitle: 'View your profile and you can update',
              ),

              const SizedBox(height: AppSpacing.lg),

              /// 👤 User Card
              const ProfileUserCard(
                name: 'Jhon Doe',
                email: 'jhondoe@gmail.com',
                phone: '+91 6261701018',
              ),

              const SizedBox(height: AppSpacing.xl),

              /// 🔗 Quick Links
              ProfileQuickLinks(links: links),

              const SizedBox(height: AppSpacing.sm),

              /// 🚪 Logout
              ProfileLinkTile(
                icon: Icons.logout,
                label: 'Logout',
                isDestructive: true,
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  AppPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}