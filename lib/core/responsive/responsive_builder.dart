import 'package:flutter/material.dart';
import 'device_type.dart';
import 'responsive_breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  DeviceType deviceType,
);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveBreakpoints.getDeviceType(context);
        return builder(context, constraints, deviceType);
      },
    );
  }
}
