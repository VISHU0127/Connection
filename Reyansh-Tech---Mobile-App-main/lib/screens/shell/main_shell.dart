import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/app_nav_bar.dart';
import 'package:my_app/core/widgets/main_shell_scope.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/alerts/alerts_screen.dart';
import 'package:my_app/screens/home/home_screen.dart';
import 'package:my_app/screens/emergency_contacts/add_emergency_contact_screen.dart';
import 'package:my_app/screens/emergency_contacts/emergency_contact_screen.dart';
import 'package:my_app/screens/medical_info/medical_info_screen.dart';
import 'package:my_app/screens/personal_info/personal_info_screen.dart';
import 'package:my_app/screens/privacy_policy/privacy_policy_screen.dart';
import 'package:my_app/screens/profile/profile_screen.dart';
import 'package:my_app/screens/safety/safety_screen.dart';
import 'package:my_app/screens/tracking/tracking_screen.dart';
import 'package:my_app/screens/vehicle/vehicle_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final List<int> _history = [];

  static const List<AppNavBarItem> _navItems = [
    AppNavBarItem(icon: Icons.home_outlined, label: 'Home'),
    AppNavBarItem(icon: Icons.location_on_outlined, label: 'Tracking'),
    AppNavBarItem(icon: Icons.error_outline, label: 'Alerts'),
    AppNavBarItem(icon: Icons.shield_outlined, label: 'Safety'),
    AppNavBarItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateTo(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _history.add(_currentIndex);
      _currentIndex = index;
    });
  }

  void _onTabTap(int index) {
    // Tapping a navbar tab clears sub-screen history and goes to that tab
    setState(() {
      _history.clear();
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToTracking: () => _navigateTo(1),
        onNavigateToSafety: () => _navigateTo(3),
        onNavigateToAlerts: () => _navigateTo(2),
      ),
      const TrackingScreen(),
      const AlertsScreen(),
      const SafetyScreen(),
      ProfileScreen(
        onNavigateToVehicle: () => _navigateTo(5),
        onNavigateToMedical: () => _navigateTo(6),
        onNavigateToPersonalInfo: () => _navigateTo(7),
        onNavigateToPrivacyPolicy: () => _navigateTo(8),
        onNavigateToEmergencyContacts: () => _navigateTo(9),
      ),
      const VehicleScreen(),
      const MedicalInfoScreen(isOnboarding: false),
      const PersonalInfoScreen(),
      const PrivacyPolicyScreen(),
      EmergencyContactsScreen(
        onNavigateToAddContact: () => _navigateTo(10),
      ),
      const AddEmergencyContactScreen(isOnboarding: false),
    ];

    return PopScope(
      canPop: _currentIndex == 0 && _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          _currentIndex = _history.isNotEmpty ? _history.removeLast() : 0;
        });
      },
      child: MainShellScope(
        child: Container(
        decoration: AppTheme.screenBackground,
        child: AppScaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: AppNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTap,
            items: _navItems,
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
      ),
      ),
    );
  }
}
