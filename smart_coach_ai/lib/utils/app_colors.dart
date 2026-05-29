import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color deepBlue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color softPurple = Color(0xFFF3ECFF);
  static const Color background = Color(0xFFF7FBFF);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF172033);
  static const Color textMuted = Color(0xFF758195);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFFB7185);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFEAF8FF), Color(0xFFF7F0FF), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
