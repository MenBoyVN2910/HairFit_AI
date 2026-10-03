// ============================================================================
// File: lib/core/constants/app_text_styles.dart
// Mục đích: Lưu trữ các hằng số dùng chung toàn ứng dụng.
// Kết cấu:
//  - Các biến static const như màu sắc, kích thước, text style hoặc business rules.
// ============================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Hệ thống kiểu chữ (Typography) của HairFit AI
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'BeVietnamPro';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Subtitles & Labels
  static const TextStyle subtitleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Buttons
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.1,
  );

  // Caption & Overline
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
  );
}
