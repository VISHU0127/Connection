import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_input_field.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/medical_info/medical_info_screen.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  final bool isOnboarding;

  const AddEmergencyContactScreen({super.key, this.isOnboarding = true});

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState
    extends State<AddEmergencyContactScreen> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacement(
        AppPageRoute(builder: (_) => const MedicalInfoScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onContinue() {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const MedicalInfoScreen()),
      (route) => false,
    );
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _relationController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔝 Header
                    AppHeader(
                      title: 'Add Contact',
                      subtitle: "They'll be notified in case of emergency",
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    /// 👤 Name
                    AppInputField(
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// 🤝 Relation
                    AppInputField(
                      label: 'Relation',
                      hint: 'e.g. Father, Mother, Spouse',
                      controller: _relationController,
                      prefixIcon: Icons.people_outline,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// 📞 Phone
                    AppInputField(
                      label: 'Phone Number',
                      hint: 'e.g. +91 98765 43210',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+ ]'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    /// ➕ Add button — inline below form
                    AppPrimaryButton(
                      label: 'Add',
                      onPressed: _isValid ? _onAdd : null,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            /// ▶ Continue button — only shown during onboarding
            if (widget.isOnboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: AppPrimaryButton(
                  label: 'Continue',
                  onPressed: _onContinue,
                ),
              )
            else
              const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
