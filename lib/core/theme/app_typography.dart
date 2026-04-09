import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract class AppTypography {
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
          color: AppColors.obsidian,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.obsidian,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: AppColors.obsidian,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.obsidian,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppColors.obsidian,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.obsidian,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: AppColors.gray500,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.gray700,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.57,
          color: AppColors.gray700,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.gray500,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.obsidian,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.obsidian,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.obsidian,
        ),
      );
}
