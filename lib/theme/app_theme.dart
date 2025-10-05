import 'package:flutter/material.dart';

class AppTheme {
  // 색상 정의
  static const Color primaryColor = Color(0xFF00C9A7); // 메인 민트색
  static const Color backgroundColor = Color(0xFFE6F4F1); // 소프트 배경
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF323232); // 폰트 블랙
  static const Color textSecondaryColor = Color(0xFF7F7F7F); // 그레이 600
  static const Color kakaoYellow = Color(0xFFFEE500);
  
  // 폰트 정의
  static const String primaryFontFamily = 'Pretendard'; // 원하는 폰트로 변경 가능
  
  // 텍스트 스타일 정의
  static const TextStyle headingLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: 2,
    fontStyle: FontStyle.italic, // 이탤릭체 추가
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textSecondaryColor,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black, // 카카오 버튼용
  );
  
  // 카드 스타일
  static CardThemeData get cardTheme => CardThemeData(
    color: surfaceColor,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
  
  // 버튼 스타일
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minimumSize: const Size(double.infinity, 56),
    ),
  );
  
  // 앱바 스타일
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: backgroundColor,
    foregroundColor: textPrimaryColor,
    elevation: 0,
    centerTitle: true,
  );
  
  // 전체 테마
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    fontFamily: primaryFontFamily,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: appBarTheme,
    cardTheme: cardTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    textTheme: const TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
    ),
    useMaterial3: true,
  );
}
