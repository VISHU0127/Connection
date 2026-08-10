import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_input_field.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      label: 'Phone Number',
      hint: '+91 00000 00000',
      controller: controller,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone_outlined,
      inputFormatters: [_PhoneInputFormatter()],
    );
  }
}

/// Custom formatter to auto-format as +91 XXXXXXXXXX
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip the '+91 ' prefix first, then extract only the user-typed digits
    String stripPrefix(String text) {
      if (text.startsWith('+91 ')) return text.substring(4);
      if (text.startsWith('+91')) return text.substring(3);
      return text;
    }

    String userDigits = stripPrefix(newValue.text).replaceAll(RegExp(r'\D'), '');
    String oldUserDigits = stripPrefix(oldValue.text).replaceAll(RegExp(r'\D'), '');

    // Backspace: user is deleting
    if (newValue.text.length < oldValue.text.length) {
      userDigits = oldUserDigits.isEmpty
          ? ''
          : oldUserDigits.substring(0, oldUserDigits.length - 1);
    }

    // Limit to 10 digits
    if (userDigits.length > 10) {
      userDigits = userDigits.substring(0, 10);
    }

    if (userDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '+91 $userDigits';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
