import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_primary_button.dart';

class ConnectPairButton extends StatelessWidget {
  final bool isPairing;
  final VoidCallback onPressed;

  const ConnectPairButton({
    super.key,
    required this.isPairing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppPrimaryButton(
        label: isPairing ? 'Pairing...' : 'Start Pairing',
        onPressed: isPairing ? null : onPressed,
      ),
    );
  }
}
