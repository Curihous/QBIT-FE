import 'env_config.dart';

class AppConfig {
  // 카카오 네이티브 앱 키 (로그인 전용)
  static String get kakaoNativeAppKey => EnvConfig.kakaoNativeAppKey;
  
  // 백엔드 API 설정
  static String get backendUrl => EnvConfig.backendUrl;
  
  // 앱 설정
  static String get appName => EnvConfig.appName;
  static String get appDescription => EnvConfig.appDescription;
}

