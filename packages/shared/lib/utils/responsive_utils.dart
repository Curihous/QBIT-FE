import 'package:flutter/material.dart';

/// 반응형 디자인을 위한 유틸리티 클래스
class ResponsiveUtils {
  // 디자인 기준 화면 크기 
  static const double _designWidth = 393.0;
  static const double _designHeight = 853.0;
  
  /// 화면 너비 기준 스케일 계산
  static double widthScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / _designWidth;
  }
  
  /// 화면 높이 기준 스케일 계산
  static double heightScale(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight / _designHeight;
  }
  
  /// 너비 기준 반응형 값 계산
  static double w(BuildContext context, double designValue) {
    return designValue * widthScale(context);
  }
  
  /// 높이 기준 반응형 값 계산
  static double h(BuildContext context, double designValue) {
    return designValue * heightScale(context);
  }

  /// 폰트 크기 반응형 값 계산
  static double f(BuildContext context, double designValue) {
    return designValue * widthScale(context);
  }
  
  /// 화면 너비
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// 화면 높이
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// 안전 영역을 제외한 화면 높이
  static double safeHeight(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return screenHeight(context) - padding.top - padding.bottom;
  }
}

/// BuildContext extension으로 더 쉽게 사용
extension ResponsiveExtension on BuildContext {
  double w(double value) => ResponsiveUtils.w(this, value);
  double h(double value) => ResponsiveUtils.h(this, value);
  double f(double value) => ResponsiveUtils.f(this, value); // Font size
  double get screenWidth => ResponsiveUtils.screenWidth(this);
  double get screenHeight => ResponsiveUtils.screenHeight(this);
  double get safeHeight => ResponsiveUtils.safeHeight(this);
}

