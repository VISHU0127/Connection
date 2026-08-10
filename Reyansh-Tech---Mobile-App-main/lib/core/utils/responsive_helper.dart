import 'package:flutter/material.dart';
import '../constants/app_breakpoints.dart';

enum DeviceType { phone, tablet }

class ResponsiveHelper {
  /// Returns the [DeviceType] based on the screen's shortest side.
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.shortestSide;
    return width >= AppBreakpoints.tablet ? DeviceType.tablet : DeviceType.phone;
  }

  static bool isPhone(BuildContext context) =>
      getDeviceType(context) == DeviceType.phone;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;
}
