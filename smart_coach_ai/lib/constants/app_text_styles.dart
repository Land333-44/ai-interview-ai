import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  // Design System Typography
  static TextTheme get textTheme {
    return GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.textSoft,
      displayColor: AppColors.text,
    );
  }

  static TextStyle get screenTitle => GoogleFonts.sora(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get title => GoogleFonts.sora(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get title2 => GoogleFonts.sora(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      );

  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSoft,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 10,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get label => GoogleFonts.dmSans(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.muted,
      );

  static TextStyle get button => GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
