import 'package:flutter/material.dart';

/// Every color used in the app. Screens must use these instead of
/// hard-coded colors, so the whole app looks like one design.
/// The values match the "Tokens" variables in the shared Figma file.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFEDE9FE);

  /// Used for compatibility scores (match %).
  static const Color accent = Color(0xFF14B8A6);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Lines and inactive elements
  static const Color border = Color(0xFFE2E8F0);
  static const Color disabled = Color(0xFFCBD5E1);
}
