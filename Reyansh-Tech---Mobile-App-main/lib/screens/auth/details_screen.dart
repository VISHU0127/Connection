import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_input_field.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/screens/shell/main_shell.dart';

class DetailsScreen extends StatefulWidget {
  final String qrData;

  const DetailsScreen({super.key, required this.qrData});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  // Personal Details Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Vehicle Details Controllers
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _registrationDateController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _chassisNumberController.dispose();
    _engineNumberController.dispose();
    _registrationNumberController.dispose();
    _registrationDateController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        _vehicleModelController.text.isEmpty || 
        _chassisNumberController.text.isEmpty ||
        _engineNumberController.text.isEmpty ||
        _registrationNumberController.text.isEmpty ||
        _registrationDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    // Basic email validation
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return false;
    }

    return true;
  }

   Future<void> _pickRegistrationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.textPrimary,
              onPrimary: AppColors.primaryBackground,
              surface: AppColors.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _registrationDateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  void _onContinue() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    // Simulate saving data locally
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);

      // Navigate to home/dashboard
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(
          builder: (_) => const MainShell(),
        ),
        (route) => false,
      );
    }
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
                      title: 'Complete Your Profile',
                      subtitle:
                          'Add your personal and vehicle details to get started',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'Personal Details',
                      style: AppTextStyles.title(context),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// First Name
                    AppInputField(
                      label: 'First Name',
                      hint: 'Enter your first name',
                      controller: _firstNameController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Last Name
                    AppInputField(
                      label: 'Last Name',
                      hint: 'Enter your last name',
                      controller: _lastNameController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Phone Number
                    AppInputField(
                      label: 'Phone Number',
                      hint: '+91 98765 43210',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Email
                    AppInputField(
                      label: 'Email',
                      hint: 'your.email@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'Vehicle Details',
                      style: AppTextStyles.title(context),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Vehicle Number
                    AppInputField(
                      label: 'Vehicle Number',
                      hint: 'e.g., MH 02 AB 1234',
                      controller: _vehicleNumberController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Vehicle Model
                    AppInputField(
                      label: 'Vehicle Model',
                      hint: 'e.g., Mercedes S650',
                      controller: _vehicleModelController,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Chassis Number
                    AppInputField(
                      label: 'Chassis Number',
                      hint: 'e.g., MA3FJEB1S00100001',
                      controller: _chassisNumberController,
                      prefixIcon: Icons.numbers_outlined,
                      ),

                    const SizedBox(height: AppSpacing.md),

                    /// Engine Number
                    AppInputField(
                      label: 'Engine Number',
                      hint: 'e.g., K10B1234567',
                      controller: _engineNumberController,
                      prefixIcon: Icons.settings_outlined,
                      ),

                    const SizedBox(height: AppSpacing.md),

                    /// Registration number
                    AppInputField(
                      label: 'Registration Number',
                      hint: 'e.g., MH02 2024 1234567',
                      controller: _registrationNumberController,
                      prefixIcon: Icons.article_outlined,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// Registration Date — tappable field
                   GestureDetector(
                      onTap: _pickRegistrationDate,
                      child: AbsorbPointer(
                        child: AppInputField(
                          label: 'Registration Date',
                          hint: 'DD/MM/YYYY',
                          controller: _registrationDateController,
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    /// Info Box
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outlined,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Your data is stored locally and used for device pairing and emergency contact purposes.',
                              style: AppTextStyles.captionMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            /// Continue Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppPrimaryButton(
                label: _isLoading ? 'Setting up...' : 'Continue',
                onPressed: _isLoading ? null : _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
