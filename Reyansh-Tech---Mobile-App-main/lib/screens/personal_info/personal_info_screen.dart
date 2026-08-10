import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_input_field.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _firstNameController = TextEditingController(text: 'Jhon');
  final _lastNameController = TextEditingController(text: 'Doe');
  final _ageController = TextEditingController(text: '25');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onSave() {
    // handle save
  }

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
                      title: 'Personal Information',
                      subtitle: 'Edit your personal information',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    /// 📝 First Name
                    AppInputField(
                      label: 'First Name',
                      hint: 'Enter your first name',
                      controller: _firstNameController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// 📝 Last Name
                    AppInputField(
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      controller: _lastNameController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// 📝 Age
                    AppInputField(
                      label: 'Age',
                      hint: 'Enter your age',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            /// 💾 Save Button — pinned above keyboard
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: AppPrimaryButton(label: 'Save', onPressed: _onSave),
            ),
          ],
        ),
      ),
    );
  }
}