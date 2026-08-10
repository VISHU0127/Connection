import 'package:flutter/material.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/screens/connect/connect.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'widgets/pair_ripple_animation.dart';
import 'widgets/connect_instructions.dart';
import 'widgets/connect_pair_button.dart';

class PairPage extends StatefulWidget {
  const PairPage({super.key});

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late Animation<double> _pulseAnimation1;
  late Animation<double> _pulseAnimation2;
  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;

  bool _isPairing = false;

  @override
  void initState() {
    super.initState();

    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation1 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );
    _pulseAnimation2 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );
    _fadeAnimation1 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController1, curve: Curves.easeOut),
    );
    _fadeAnimation2 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController2, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _pulseController2.forward(from: 0.5);
    });
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    super.dispose();
  }

  void _startPairing() {
    setState(() => _isPairing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.push(
          context,
          AppPageRoute(builder: (_) => const ConnectPage(qrData: 'DEVICE_PAIRED', fromLogin: true)),
        );
        setState(() => _isPairing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppHeader(
                title: 'Pair Device',
                subtitle: 'Connect your device for accident detection',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            PairAnimation(
              pulseAnimation1: _pulseAnimation1,
              pulseAnimation2: _pulseAnimation2,
              fadeAnimation1: _fadeAnimation1,
              fadeAnimation2: _fadeAnimation2,
              listenable: Listenable.merge([_pulseController1, _pulseController2]),
              isPairing: _isPairing,
            ),

            const ConnectInstructions(),

            const SizedBox(height: AppSpacing.lg),

            ConnectPairButton(
              isPairing: _isPairing,
              onPressed: _startPairing,
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}