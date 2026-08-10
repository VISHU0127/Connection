import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_input_field.dart';

/// Thin wrapper kept for backward compatibility.
/// Internally uses the shared AppInputField.
class MedicalTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const MedicalTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      label: label,
      hint: hint,
      controller: controller,
    );
  }
}