import 'package:flutter/material.dart';
import '../../../core/widgets/app_primary_button.dart';

class AddContactButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddContactButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: '+ Add Emergency Contact',
      onPressed: onTap,
    );
  }
}