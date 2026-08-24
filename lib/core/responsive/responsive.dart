import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  // Breakpoints
  static const double mobileMax = 599.0;
  static const double tabletMax = 1199.0;
  static const double desktopMax = 1599.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > mobileMax &&
      MediaQuery.sizeOf(context).width <= tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax &&
      MediaQuery.sizeOf(context).width <= desktopMax;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > desktopMax;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= tabletMax;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width > desktopMax && largeDesktop != null) {
      return largeDesktop!;
    } else if (width > tabletMax) {
      return desktop;
    } else if (width > mobileMax && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final List<Widget> inputChildren = children.where((c) {
      if (c is SizedBox && c.width != null && c.height == null) {
        return false;
      }
      return true;
    }).toList();

    final List<Widget> processedChildren = [];

    if (isMobile) {
      for (int i = 0; i < inputChildren.length; i++) {
        var child = inputChildren[i];
        if (child is Expanded) {
          child = child.child;
        } else if (child is Flexible) {
          child = child.child;
        }
        processedChildren.add(child);
        if (i < inputChildren.length - 1) {
          processedChildren.add(SizedBox(height: spacing));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: processedChildren,
      );
    } else {
      for (int i = 0; i < inputChildren.length; i++) {
        processedChildren.add(inputChildren[i]);
        if (i < inputChildren.length - 1) {
          processedChildren.add(SizedBox(width: spacing));
        }
      }
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        children: processedChildren,
      );
    }
  }
}
