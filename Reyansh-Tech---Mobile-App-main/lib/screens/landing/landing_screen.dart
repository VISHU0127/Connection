import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import '../../core/widgets/app_logo_header.dart';
import 'models/landing_slide.dart';
import 'widgets/landing_page_view.dart';
import 'widgets/landing_dots.dart';
import 'widgets/landing_buttons.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentIndex) {
        setState(() => _currentIndex = page);
      }
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final nextIndex = (_currentIndex + 1) % landingSlides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// 🔝 Logo + Title
            const AppLogoHeader(),

            /// 🖼 Sliding Images + Text
            LandingPageView(
              controller: _pageController,
              slides: landingSlides,
            ),

            /// ⚫ Dots Indicator
            LandingDots(
              count: landingSlides.length,
              currentIndex: _currentIndex,
            ),

            /// 🚀 Action Buttons
            const LandingButtons(),
          ],
        ),
      ),
    );
  }
}
