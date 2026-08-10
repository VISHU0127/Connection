import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/app_page_route.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_scaffold.dart';
import '../connect/pair.dart';
import 'widgets/auth_header.dart';
import 'widgets/otp_input_field.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Key to imperatively trigger a resend restart on the timer widget
  final GlobalKey<_ResendTimerState> _resendKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _otpController.addListener(() {
      if (_otpController.text.length == 6) {
        _onVerify();
      }
    });
  }

  void _onResend() {
    _otpController.clear();
    _focusNode.requestFocus();
    _resendKey.currentState?.restart();
  }

  void _onVerify() {
    final otp = _otpController.text;
    if (otp.length < 6) return;

    Navigator.pushReplacement(
      context,
      AppPageRoute(builder: (_) => const PairPage()),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              AuthHeader(
                title: 'Verify your number',
                subtitle:
                    'Enter the 6-digit code sent to ${widget.phoneNumber}',
              ),

              /// 🔢 OTP Boxes
              OtpInputField(
                controller: _otpController,
                focusNode: _focusNode,
              ),

              const SizedBox(height: AppSpacing.lg),

              /// ✅ Verify Button
              AppPrimaryButton(
                label: 'Verify',
                onPressed: _onVerify,
              ),

              const SizedBox(height: AppSpacing.lg),

              /// 🔁 Resend
              _ResendTimer(key: _resendKey, onResend: _onResend),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isolated countdown widget — its setState never touches the OTP fields above.
class _ResendTimer extends StatefulWidget {
  final VoidCallback onResend;
  const _ResendTimer({super.key, required this.onResend});

  @override
  State<_ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<_ResendTimer> {
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void restart() {
    _timer?.cancel();
    _start();
  }

  void _start() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsRemaining == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _canResend
          ? GestureDetector(
              onTap: widget.onResend,
              child: Text(
                "Didn't receive the code? Resend",
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          : Text(
              "Didn't receive the code? Resend in ${_secondsRemaining}s",
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
    );
  }
}
