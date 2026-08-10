import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class AppDimensions {
  final double shortestSide;
  final double height;
  final double width;
  final DeviceType deviceType;

  AppDimensions(BuildContext context)
      : shortestSide = MediaQuery.of(context).size.shortestSide,
        height = MediaQuery.of(context).size.height,
        width = MediaQuery.of(context).size.width,
        deviceType = ResponsiveHelper.getDeviceType(context);

  bool get _isTablet => deviceType == DeviceType.tablet;

  // Logo
  double get logoHeight => shortestSide * (_isTablet ? 0.10 : 0.16);

  // Car / Hero Images
  double get carHeight => shortestSide * (_isTablet ? 0.55 : 0.70);

  // Font sizes — use these named tiers everywhere, never multiply inline
  //
  //  heading  → screen titles ("Welcome", "Pair Device")
  //  title    → section titles
  //  body     → input text, card text
  //  label    → input labels, blood group selector label
  //  caption  → terms text, resend text, helper text
  double get fontSizeHeading => shortestSide * (_isTablet ? 0.055 : 0.065);
  double get fontSizeTitle   => shortestSide * (_isTablet ? 0.038 : 0.045);
  double get fontSizeBodyLarge => shortestSide * (_isTablet ? 0.036 : 0.042);
  double get fontSizeBody      => shortestSide * (_isTablet ? 0.030 : 0.035);
  double get fontSizeLabel   => shortestSide * (_isTablet ? 0.024 : 0.028);
  double get fontSizeSmall   => shortestSide * (_isTablet ? 0.028 : 0.034);
  double get fontSizeCaption => shortestSide * (_isTablet ? 0.024 : 0.030);

  // Letter spacing
  double get letterSpacingNormal => shortestSide * 0.002;
  double get letterSpacingWide   => shortestSide * 0.004;
}
