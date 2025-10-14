import 'package:flutter/material.dart';

// 반응형 유틸리티 클래스
// 기준 화면: 393 x 853
class ResponsiveUtil {
  static const double baseWidth = 393.0;
  static const double baseHeight = 853.0;

  // 현재 화면의 너비 스케일 팩터
  static double getWidthScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / baseWidth;
  }

  // 현재 화면의 높이 스케일 팩터
  static double getHeightScale(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight / baseHeight;
  }

  // 너비 기준 반응형 값 계산
  static double w(BuildContext context, double baseValue) {
    return baseValue * getWidthScale(context);
  }

  // 높이 기준 반응형 값 계산
  static double h(BuildContext context, double baseValue) {
    return baseValue * getHeightScale(context);
  }

  // 폰트 크기 계산 (너비 기준)
  static double sp(BuildContext context, double baseFontSize) {
    return baseFontSize * getWidthScale(context);
  }

  // 현재 화면 너비
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // 현재 화면 높이
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

// extension
extension ResponsiveExtension on BuildContext {
  // 너비 기준 반응형 값
  double w(double baseValue) => ResponsiveUtil.w(this, baseValue);
  
  // 높이 기준 반응형 값
  double h(double baseValue) => ResponsiveUtil.h(this, baseValue);
  
  // 폰트 크기
  double sp(double baseFontSize) => ResponsiveUtil.sp(this, baseFontSize);
  
  // 화면 너비
  double get screenWidth => ResponsiveUtil.screenWidth(this);
  
  // 화면 높이
  double get screenHeight => ResponsiveUtil.screenHeight(this);
}

