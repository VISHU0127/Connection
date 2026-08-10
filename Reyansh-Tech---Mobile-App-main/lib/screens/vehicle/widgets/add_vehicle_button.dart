import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_secondary_button.dart';

class AddVehicleButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddVehicleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: '+ Add New Vehicle',
      onTap: onTap,
      fullWidth: true,
    );
  }
}