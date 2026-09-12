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
  static const double compactMax = 799.0;
  static const double tabletMax = 1199.0;
  static const double desktopMax = 1599.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= compactMax;

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

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width <= mobileMax
        ? 16.0
        : width <= tabletMax
        ? 24.0
        : 32.0;
    return EdgeInsets.all(horizontal);
  }

  /// How many equal columns a [ResponsiveRow] should use for [childCount].
  /// Uses available content width (after sidebar), not the full window.
  static int columnsForWidth(double width, int childCount) {
    if (childCount <= 1) return 1;
    if (!width.isFinite || width <= compactMax) return 1;
    if (width <= tabletMax) return 2;
    return childCount;
  }

  static int columnsFor(BuildContext context, int childCount) {
    return columnsForWidth(MediaQuery.sizeOf(context).width, childCount);
  }

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

  Widget _unwrap(Widget child) {
    if (child is Expanded) return child.child;
    if (child is Flexible) return child.child;
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inputChildren = children.where((c) {
          if (c is SizedBox &&
              c.child == null &&
              c.width != null &&
              c.height == null) {
            return false;
          }
          return true;
        }).toList();

        if (inputChildren.isEmpty) return const SizedBox.shrink();

        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = Responsive.columnsForWidth(width, inputChildren.length);

        if (columns == 1) {
          final stacked = <Widget>[];
          for (var i = 0; i < inputChildren.length; i++) {
            stacked.add(_unwrap(inputChildren[i]));
            if (i < inputChildren.length - 1) {
              stacked.add(SizedBox(height: spacing));
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stacked,
          );
        }

        if (columns >= inputChildren.length) {
          final rowChildren = <Widget>[];
          for (var i = 0; i < inputChildren.length; i++) {
            rowChildren.add(inputChildren[i]);
            if (i < inputChildren.length - 1) {
              rowChildren.add(SizedBox(width: spacing));
            }
          }
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: rowChildren,
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < inputChildren.length; i += columns) {
          final slice = inputChildren.skip(i).take(columns).toList();
          final rowKids = <Widget>[];
          for (var j = 0; j < slice.length; j++) {
            rowKids.add(Expanded(child: _unwrap(slice[j])));
            if (j < slice.length - 1) {
              rowKids.add(SizedBox(width: spacing));
            }
          }
          for (var j = slice.length; j < columns; j++) {
            rowKids.add(SizedBox(width: spacing));
            rowKids.add(const Expanded(child: SizedBox.shrink()));
          }
          rows.add(
            Row(
              crossAxisAlignment: crossAxisAlignment,
              children: rowKids,
            ),
          );
          if (i + columns < inputChildren.length) {
            rows.add(SizedBox(height: spacing));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
