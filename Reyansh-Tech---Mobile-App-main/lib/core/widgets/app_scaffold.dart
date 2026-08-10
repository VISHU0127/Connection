import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_shell_scope.dart';

/// Drop-in replacement for [Scaffold] that paints [AppTheme.screenBackground]
/// (the bottom-left orange radial orb) behind every screen body.
///
/// Usage:
/// ```dart
/// AppScaffold(
///   body: SafeArea(child: ...),
///   appBar: AppBar(...),          // optional
///   bottomNavigationBar: ...,     // optional
///   resizeToAvoidBottomInset: false, // optional
/// )
/// ```
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.backgroundColor = AppColors.primaryBackground,
    this.appBar,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg =
        MainShellScope.isActive(context) ? Colors.transparent : backgroundColor;
    return Scaffold(
      backgroundColor: effectiveBg,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body,
    );
  }
}
