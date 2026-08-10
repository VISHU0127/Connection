import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import '../../core/widgets/app_logo_header.dart';
import 'widgets/splash_background.dart';
import 'widgets/splash_car_section.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLanding();
  }

  void _navigateToLanding() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/landing');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          /// 🌑 Background
          const SplashBackground(),

          /// 🧠 Main Content
          SafeArea(
            child: Column(
              children: const [
                /// 🔝 Top: Logo + Title
                AppLogoHeader(expanded: true),

                /// 🚗 Bottom: Car Image
                SplashCarSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}