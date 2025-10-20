import 'package:flutter/material.dart';

/// 앱 색상 정의
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00C9A7); // 메인 민트색
  static const Color primaryDark = Color(0xFF05B99B); // 폰트 민트색 
  static const Color primaryLight = Color(0xFF4DD4B8); // 소프트 민트색
  
  // Gray Scale
  static const Color gray900 = Color(0xFF323232); // Font Black
  static const Color gray600 = Color(0xFF7F7F7F); 
  static const Color gray400 = Color(0xFFABABAB);
  static const Color gray300 = Color(0xFFBFBFBF);
  static const Color gray200 = Color(0xFFD5D5D5);
  static const Color gray150 = Color(0xFFE2E2E2);
  static const Color gray100 = Color(0xFFE8EAED);
  static const Color gray50 = Color(0xFFF3F4F6);
  static const Color gray30 = Color(0xFFF7F7F7);
  static const Color white = Color(0xFFFFFFFF); // White
  
  // Background Colors
  static const Color background = Color(0xFFE6F4F1); // 소프트 배경
  static const Color surface = white; // White
  static const Color surfaceVariant = gray50;
  
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Secondary Colors
  
  static const Color secondaryMain = Color(0xFFFFE19C); // Secondary main
  static const Color secondaryLight = Color(0xFFFCE6B3); // Secondary soft
  static const Color secondaryBG = Color(0xFFFFFBF3); // BG
  
  // Trade Colors
  static const Color loss = Color(0xFFE74C3C); // 빨간색 (하락)
  static const Color profit = Color(0xFF178EDE); // 파란색 (상승)
  
  // Order Book Bar Colors
  static const Color orderBookBidBg = Color(0x33178EDE); 
  static const Color orderBookAskBg = Color(0x33E74C3C); 
  
  
  // Neutral Colors
  static const Color black = gray900;
  static const Color transparent = Colors.transparent;
  
  // Border Colors
  static const Color border = gray200;
  static const Color borderLight = gray100;
}


/// 앱 간격 정의
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}


/// 앱 둥근 모서리 정의
class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
}

/// 앱 그림자 정의
class AppShadows {
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}
