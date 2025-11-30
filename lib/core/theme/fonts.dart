// lib/core/theme/fonts.dart
import 'package:flutter/material.dart';

import 'colors.dart';

class AppFonts {
  // Font Family (기본 시스템 폰트 사용, 필요시 pubspec.yaml에 커스텀 폰트 추가)
  static const String primaryFont = 'NotoSansKR';

  // Font Sizes
  static const double titleLarge = 48.0;
  static const double titleMedium = 32.0;
  static const double bodyLarge = 18.0;
  static const double bodyMedium = 16.0;
  static const double bodySmall = 14.0;

  // Font Weights
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;

  // Text Styles
  static TextStyle titleStyle = const TextStyle(
    fontSize: titleLarge,
    fontWeight: bold,
    color: AppColors.primary,
    letterSpacing: 2.0,
  );

  static TextStyle buttonTextStyle = const TextStyle(
    fontSize: bodyMedium,
    fontWeight: medium,
    color: AppColors.textPrimary,
  );
}