import 'env_config.dart';

class AppConfig {
  // 카카오 앱 키 
  static String get kakaoNativeAppKey => EnvConfig.kakaoNativeAppKey;
  
  // 카카오 REST API 키 (REST API 방식용)
  static String get kakaoRestApiKey => EnvConfig.kakaoRestApiKey;
  
  // 백엔드 API 설정
  static String get baseUrl => EnvConfig.baseUrl;
  static String get backendUrl => EnvConfig.backendUrl;
  
  // 카카오 OAuth 설정
  static String get kakaoRedirectUri => EnvConfig.kakaoRedirectUri;
  
  // 개발용 로컬호스트 설정
  static String get localhostPort => EnvConfig.localhostPort;
  static String get localhostUrl => EnvConfig.localhostUrl;
  
  // 앱 설정
  static String get appName => EnvConfig.appName;
  static String get appDescription => EnvConfig.appDescription;
}

