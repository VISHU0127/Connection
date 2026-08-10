import 'package:flutter/material.dart';
import '../../../core/utils/app_page_route.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';

class LandingButtons extends StatelessWidget {
  const LandingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final hPad = dim.shortestSide * 0.06;
    final gap = dim.shortestSide * 0.03;
    final bottomPad = dim.shortestSide * 0.05;
    final height = dim.shortestSide * 0.13;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, gap * 1.5, hPad, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🚀 Login — black bg, white border, white text
          SizedBox(
            width: double.infinity,
            height: height,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                AppPageRoute(builder: (_) => const LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  side: const BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              child: Text('Login', style: AppTextStyles.buttonLabel(context).copyWith(color: Colors.white)),
            ),
          ),

          SizedBox(height: gap),

          /// 📝 Sign Up
          AppPrimaryButton(
            label: 'Sign Up',
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => const SignUpScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
