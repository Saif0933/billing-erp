import 'package:flutter/material.dart';
import 'device_type.dart';

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMax = 1023.0;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= mobileMax) {
      return DeviceType.mobile;
    } else if (width <= tabletMax) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;
  static bool isMobileOrTablet(BuildContext context) => getDeviceType(context) != DeviceType.desktop;
}
