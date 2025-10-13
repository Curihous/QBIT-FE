import 'package:flutter/material.dart';

/// 앱 타이포그래피 정의
class AppTypography {
  static const String fontFamily = 'Pretendard';
  
  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 26 / 22, // line-height: 26
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 24 / 20, // line-height: 24
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 24 / 20, // line-height: 24
  );
  
  // Body Styles
  static const TextStyle bodyLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semi-Bold
    height: 24 / 16, // line-height: 24
  );
  
  static const TextStyle bodyLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    height: 24 / 16, // line-height: 24
  );
  
  static const TextStyle bodyMediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 140 / 16, // line-height: 140 (디자인 스펙에 따라)
  );
  
  // Caption Styles
  static const TextStyle captionLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semi-Bold
    height: 24 / 14, // line-height: 24
  );
  
  static const TextStyle captionLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 24 / 14, // line-height: 24
  );
  
  static const TextStyle captionLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500, // Medium
    height: 24 / 13, // line-height: 24
  );
  
  static const TextStyle captionSmallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400, // Regular
    height: 24 / 11, // line-height: 24
  );
  
  // Button Styles
  static const TextStyle btn1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 24 / 20, // line-height: 24
  );
  
  static const TextStyle btn2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 24 / 14, // line-height: 24
  );
}
