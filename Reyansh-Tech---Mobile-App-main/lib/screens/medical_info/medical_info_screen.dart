import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/screens/auth/widgets/auth_header.dart';
import 'package:my_app/screens/shell/main_shell.dart';
import 'widgets/blood_group_selector.dart';
import 'widgets/medical_text_field.dart';

class MedicalInfoScreen extends StatefulWidget {
  final bool isOnboarding;

  const MedicalInfoScreen({super.key, this.isOnboarding = true});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  String _selectedBloodGroup = 'A+';
  final TextEditingController _allergiesController = TextEditingController(
    text: '',
  );
  final TextEditingController _conditionController = TextEditingController(
    text: '',
  );

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _onLetsGo() {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  void _onSave() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            /// 📜 Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔝 Header
                    if (widget.isOnboarding)
                      AuthHeader(
                        title: 'Medical Information',
                        subtitle:
                            'Help emergency responders provide better care',
                      )
                    else
                      AppHeader(
                        title: 'Medical Information',
                        subtitle:
                            'Help emergency responders provide better care',
                      ),

                    /// 🩸 Blood Group
                    const SizedBox(height: AppSpacing.lg),
                    BloodGroupSelector(
                      selected: _selectedBloodGroup,
                      onSelected: (val) =>
                          setState(() => _selectedBloodGroup = val),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    /// 🌿 Allergies
                    MedicalTextField(
                      label: 'Allergies',
                      hint: 'e.g. Peanut, Dust',
                      controller: _allergiesController,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    /// 🏥 Medical Condition
                    MedicalTextField(
                      label: 'Medical Condition',
                      hint: 'e.g. Diabetes, High Blood Pressure',
                      controller: _conditionController,
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            /// ✅ Let's Go Button — pinned above keyboard
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: AppPrimaryButton(
                label: widget.isOnboarding ? "Let's Go" : 'Save',
                onPressed: widget.isOnboarding ? _onLetsGo : _onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
