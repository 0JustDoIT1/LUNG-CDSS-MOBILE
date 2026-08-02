import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF66B5F8);
  static const Color primaryDark = Color(0xFF2F80C9);
  static const Color secondary = Color(0xFF69D5B1);

  // Background
  static const Color background = Color(0xFFF6FAFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1F6FA);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textDisabled = Color(0xFF98A2B3);

  // Border
  static const Color border = Color(0xFFE4E7EC);
  static const Color divider = Color(0xFFEAECF0);

  // Status
  static const Color success = Color(0xFF32B768);
  static const Color warning = Color(0xFFF2B84B);
  static const Color danger = Color(0xFFE84A5F);
  static const Color info = Color(0xFF4D9DE0);

  // Risk backgrounds
  static const Color successBackground = Color(0xFFEAF8EF);
  static const Color warningBackground = Color(0xFFFFF6DE);
  static const Color dangerBackground = Color(0xFFFFE9EC);

  // Misc
  static const Color overlay = Color(0x66000000);
}