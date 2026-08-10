import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/screens/connect/connect.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_primary_button.dart';
import 'widgets/auth_header.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  Future<void> _openScanner(BuildContext context) async {
    if (mounted) {
      final result = await Navigator.of(context).push<String>(
        AppPageRoute(
          builder: (_) => const _QRScannerScreen(),
        ),
      );

      if (result != null && mounted) {
        // QR code scanned successfully, navigate to connect page
        Navigator.of(context).push(
          AppPageRoute(
            builder: (_) => ConnectPage(qrData: result),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = AppDimensions(context);
    final scanBoxSize = dim.shortestSide * 0.55;

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// 🔝 Header
              AuthHeader(
                title: 'Scan QR Code',
                subtitle:
                    'Point your camera at the QR code on your Reyansh device to pair it instantly.',
              ),

              const Spacer(),

              /// 📷 QR Scan Box
              GestureDetector(
                onTap: () => _openScanner(context),
                child: Container(
                  width: scanBoxSize,
                  height: scanBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.panelColor,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      /// Corner brackets
                      ..._buildCorners(scanBoxSize),

                      /// Camera icon + label
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: dim.shortestSide * 0.14,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to Scan',
                              style: AppTextStyles.label(context).copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              /// Helper text
              Text(
                'Make sure the QR code is within the frame and well-lit.',
                textAlign: TextAlign.center,
                style: AppTextStyles.captionMuted(context),
              ),

              const Spacer(),

              /// 📷 Open Scanner Button
              AppPrimaryButton(
                label: 'Open Scanner',
                onPressed: () => _openScanner(context),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double size) {
    const thickness = 3.0;
    const length = 24.0;
    const radius = 6.0;
    const color = Colors.white;
    const pad = 12.0;

    Widget corner({
      required Alignment alignment,
      required BorderRadius borderRadius,
    }) =>
        Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(pad),
            child: SizedBox(
              width: length,
              height: length,
              child: CustomPaint(
                painter: _CornerPainter(
                  borderRadius: borderRadius,
                  thickness: thickness,
                  color: color,
                ),
              ),
            ),
          ),
        );

    return [
      corner(
        alignment: Alignment.topLeft,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(radius)),
      ),
      corner(
        alignment: Alignment.topRight,
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(radius)),
      ),
      corner(
        alignment: Alignment.bottomLeft,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(radius)),
      ),
      corner(
        alignment: Alignment.bottomRight,
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(radius)),
      ),
    ];
  }
}

/// Simple QR code scanner screen (demo mode without mobile_scanner package)
class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final TextEditingController _qrController = TextEditingController();

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Scan QR Code',
                    style: AppTextStyles.heading(context),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // Camera placeholder
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.lg),
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Camera Preview',
                            style: AppTextStyles.label(context),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Mobile scanner package required\nfor real QR scanning',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.captionMuted(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Manual QR code input for demo
                    Text(
                      'Demo Mode: Enter QR Code Data',
                      style: AppTextStyles.label(context),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextField(
                      controller: _qrController,
                      style: AppTextStyles.body(context),
                      decoration: InputDecoration(
                        hintText: 'e.g., DEVICE_12345_ABC',
                        hintStyle: AppTextStyles.bodyMuted(context),
                        filled: true,
                        fillColor: AppColors.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.md),
                          borderSide: const BorderSide(
                            color: AppColors.borderColor,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.md),
                          borderSide: const BorderSide(
                            color: AppColors.textPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      'To enable real QR code scanning, install the mobile_scanner package:\nflutter pub add mobile_scanner',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionMuted(context),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppPrimaryButton(
                label: 'Confirm QR Code',
                onPressed: () {
                  if (_qrController.text.isNotEmpty) {
                    Navigator.of(context).pop<String>(_qrController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter QR code data'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double thickness;
  final Color color;

  const _CornerPainter({
    required this.borderRadius,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
