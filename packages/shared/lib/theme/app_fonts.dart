import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 앱 폰트 정의 
class AppFonts {
  static const String fontFamily = 'Pretendard';
  
  // Title Styles
  static const TextStyle t1Bold = TextStyle(
    fontSize: 20,
    height: 23/20, // line-height: 23px
    fontWeight: FontWeight.w700, // Bold
    fontFamily: fontFamily,
  );
  
  static const TextStyle t2Bold = TextStyle(
    fontSize: 18,
    height: 21/18, // line-height: 21px
    fontWeight: FontWeight.w700, // Bold
    fontFamily: fontFamily,
  );
  
  static const TextStyle t2Semibold = TextStyle(
    fontSize: 18,
    height: 21/18, // line-height: 21px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  // Body Styles
  static const TextStyle b1Bold = TextStyle(
    fontSize: 16,
    height: 20/16, // line-height: 20px
    fontWeight: FontWeight.w700, // Bold
    fontFamily: fontFamily,
  );
  
  static const TextStyle b1Semibold = TextStyle(
    fontSize: 16,
    height: 20/16, // line-height: 20px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  static const TextStyle b1Regular = TextStyle(
    fontSize: 16,
    height: 20/16, // line-height: 20px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  static const TextStyle b2Semibold = TextStyle(
    fontSize: 14,
    height: 17/14, // line-height: 17px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  static const TextStyle b2Regular = TextStyle(
    fontSize: 14,
    height: 17/14, // line-height: 17px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  // Caption Styles
  static const TextStyle c1 = TextStyle(
    fontSize: 13,
    height: 16/13, // line-height: 16px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  static const TextStyle c2 = TextStyle(
    fontSize: 11,
    height: 14/11, // line-height: 14px
    fontWeight: FontWeight.w400, // Regular
    fontFamily: fontFamily,
  );
  
  // Button Styles
  static const TextStyle btn1 = TextStyle(
    fontSize: 18,
    height: 23/18, // line-height: 23px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  static const TextStyle btn2 = TextStyle(
    fontSize: 14,
    height: 17/14, // line-height: 17px
    fontWeight: FontWeight.w600, // SemiBold
    fontFamily: fontFamily,
  );
  
  static const TextStyle btn3 = TextStyle(
    fontSize: 13,
    height: 17/13, // line-height: 17px
    fontWeight: FontWeight.w400, // Regular
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
