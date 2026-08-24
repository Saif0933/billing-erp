import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF0F172A); // Deep Slate
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF020617);
  
  static const Color accent = Color(0xFF10B981); // Emerald Green (trust, growth)
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);

  // Neutral Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF475569);
  static const Color textLightMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFFCBD5E1);
  static const Color textDarkMuted = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF0F172A);

  // Status/Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Specific Business UX colors
  static const Color invoiceStatusDraft = Color(0xFF64748B);
  static const Color invoiceStatusSent = Color(0xFF3B82F6);
  static const Color invoiceStatusPaid = Color(0xFF10B981);
  static const Color invoiceStatusOverdue = Color(0xFFEF4444);
}
