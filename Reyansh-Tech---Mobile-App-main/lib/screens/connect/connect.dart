import 'package:flutter/material.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/auth/details_screen.dart';
import 'package:my_app/screens/emergency_contacts/add_emergency_contact_screen.dart';
import 'widgets/connect_ripple_animation.dart';

class ConnectPage extends StatefulWidget {
  final String qrData;
  final bool fromLogin;

  const ConnectPage({
    super.key,
    required this.qrData,
    this.fromLogin = false,
  });

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late Animation<double> _scaleAnim1;
  late Animation<double> _scaleAnim2;
  late Animation<double> _fadeAnim1;
  late Animation<double> _fadeAnim2;

  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scaleAnim1 = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );
    _fadeAnim1 = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnim2 = Tween<double>(begin: 1.0, end: 1.65).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    _fadeAnim2 = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );

    _entryController.forward().then((_) {
      _checkController.forward().then((_) {
        _pulseController2.repeat();
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _pulseController1.repeat();
        });
      });
    });
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _checkController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final h = MediaQuery.of(context).size.height;
            return Column(
          children: [
            SizedBox(height: h * 0.05),

            const AppHeader(
              title: 'Device Connected!',
              subtitle: 'Your accident detection device is now\nconnected',
            ),

            SizedBox(height: h * 0.03),

            ConnectRippleAnimation(
              entryAnim: _entryAnim,
              pulseController1: _pulseController1,
              pulseController2: _pulseController2,
              scaleAnim1: _scaleAnim1,
              fadeAnim1: _fadeAnim1,
              scaleAnim2: _scaleAnim2,
              fadeAnim2: _fadeAnim2,
              checkController: _checkController,
              checkAnim: _checkAnim,
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, h * 0.04),
              child: AppPrimaryButton(
                label: 'Continue',
                onPressed: () {
                  if (widget.fromLogin) {
                    Navigator.of(context).push(
                      AppPageRoute(
                        builder: (_) => const AddEmergencyContactScreen(
                          isOnboarding: true,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      AppPageRoute(
                        builder: (_) => DetailsScreen(qrData: widget.qrData),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
          },
        ),
      ),
    );
  }
}
