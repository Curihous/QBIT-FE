import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 폰트 정의 
class AppFonts {
  static const String fontFamily = 'Pretendard';
  
  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    height: 26/22, // line-height: 26px
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    height: 24/20, // line-height: 24px
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 20,
    height: 24/20, // line-height: 24px
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  // Body Styles
  static const TextStyle bodyLargeSemiBold = TextStyle(
    fontSize: 16,
    height: 24/16, // line-height: 24px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyLargeBold = TextStyle(
    fontSize: 16,
    height: 24/16, // line-height: 24px
    fontWeight: FontWeight.w700, // Bold
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyMediumRegular = TextStyle(
    fontSize: 16,
    height: 1.4, // line-height: 140% (1.4)
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  // 추가 폰트 스타일 (기존 코드 호환성)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodySmallSemiBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  // Caption Styles
  static const TextStyle captionLargeSemiBold = TextStyle(
    fontSize: 14,
    height: 24/14, // line-height: 24px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  // Button Styles
  static const TextStyle btn2 = TextStyle(
    fontSize: 14,
    height: 20/14, // line-height: 20px
    fontWeight: FontWeight.w500, // Medium
    fontFamily: fontFamily,
  );
  
  static const TextStyle captionLargeRegular = TextStyle(
    fontSize: 14,
    height: 24/14, // line-height: 24px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  static const TextStyle captionLargeMedium = TextStyle(
    fontSize: 13,
    height: 24/13, // line-height: 24px
    fontWeight: FontWeight.w500, // Medium
    fontFamily: fontFamily,
  );
  
  static const TextStyle captionSmallRegular = TextStyle(
    fontSize: 11,
    height: 24/11, // line-height: 24px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  // Button Styles
  static const TextStyle button1 = TextStyle(
    fontSize: 20,
    height: 24/20, // line-height: 24px
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static const TextStyle button2 = TextStyle(
    fontSize: 14,
    height: 24/14, // line-height: 24px
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  // Navigation Styles
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    height: 16/12, // line-height: 16px
    fontWeight: FontWeight.w700, // Bold
    fontFamily: fontFamily,
  );
  
  // Utility Methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
