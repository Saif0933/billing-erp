import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const BoxShadow sm = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 6,
    offset: Offset(0, 4),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x2E000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}
