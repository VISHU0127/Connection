import 'package:flutter/material.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_primary_button.dart';
import 'otp_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/phone_input_field.dart';
import 'widgets/auth_terms_text.dart';
// import 'widgets/auth_bottom_link.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => OtpScreen(phoneNumber: '+91 $phone'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              AuthHeader(
                title: 'Welcome to Reyansh',
                subtitle: 'Sign in to continue to Reyansh Technologies',
              ),

              /// 📱 Phone Input
              PhoneInputField(controller: _phoneController),

              const SizedBox(height: AppSpacing.lg),

              /// ▶ Continue Button
              AppPrimaryButton(
                label: 'Continue',
                onPressed: _onContinue,
              ),

              const SizedBox(height: AppSpacing.md),

              /// 📄 Terms
              const AuthTermsText(),

              const Spacer(),

              /// 🔗 Sign Up Link
              // AuthBottomLink(
              //   label: 'Do not have an account? ',
              //   actionText: 'Sign Up',
              //   onTap: () {},
              // ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}