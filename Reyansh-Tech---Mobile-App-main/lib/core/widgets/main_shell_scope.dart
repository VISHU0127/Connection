import 'package:flutter/widgets.dart';

/// Placed at the root of [MainShell] so that [AppScaffold] can detect
/// whether it is rendered inside the shell and use a transparent background,
/// letting the shell's gradient Container show through.
class MainShellScope extends InheritedWidget {
  const MainShellScope({super.key, required super.child});

  /// Returns `true` when the given [context] is inside [MainShell].
  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>() != null;

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}
