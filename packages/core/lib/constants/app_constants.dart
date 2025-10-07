/// QBIT 앱의 상수 정의
class AppConstants {
  // 앱 정보
  static const String appName = 'QBIT';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'QBIT - 투자 학습 플랫폼';
  
  // API 관련
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // 저장소 키
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userInfoKey = 'user_info';
  static const String isFirstLaunchKey = 'is_first_launch';
  
  // 라우트 경로
  static const String rootPath = '/';
  static const String loginPath = '/login';
  static const String homePath = '/home';
  static const String investmentPath = '/investment';
  static const String alpacaPath = '/alpaca';
  static const String debugPath = '/debug';
  
  // 투자 관련
  static const double initialBalance = 10000000.0; // 초기 모의투자 금액
  static const double minOrderAmount = 1000.0; // 최소 주문 금액
  
  // UI 관련
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  // 날짜 형식
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String timeFormat = 'HH:mm:ss';
}
