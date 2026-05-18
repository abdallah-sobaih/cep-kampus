import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background     = Color(0xFF0F1117);
  static const Color surface        = Color(0xFF1A1D27);
  static const Color surfaceAlt     = Color(0xFF222537);
  static const Color userBubble     = Color(0xFF2D5BE3);
  static const Color aiBubble       = Color(0xFF1E2235);
  static const Color accent         = Color(0xFF4F7FFF);
  static const Color accentSoft     = Color(0x334F7FFF);
  static const Color sourceChip     = Color(0xFF2A3A5C);
  static const Color sourceChipText = Color(0xFF8AB4FF);
  static const Color textPrimary    = Color(0xFFE8EAF6);
  static const Color textSecondary  = Color(0xFF8892B0);
  static const Color errorColor     = Color(0xFFFF6B6B);
  static const Color micActive      = Color(0xFFFF4757);
  static const Color divider        = Color(0xFF2A2D3E);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle messageText = TextStyle(
    fontSize: 15,
    height: 1.55,
    color: AppColors.textPrimary,
    fontFamily: 'Inter',
  );

  static const TextStyle sourceChipLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.sourceChipText,
    letterSpacing: 0.2,
    fontFamily: 'Inter',
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
    fontFamily: 'Inter',
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    fontFamily: 'Inter',
  );
}