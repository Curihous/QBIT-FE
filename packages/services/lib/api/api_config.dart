import 'package:qbit_core/config/app_config.dart';

class ApiConfig {
  static String get baseUrl => AppConfig.backendUrl;
  
  // 인증 관련 엔드포인트
  static const String kakaoLogin = '/auth/kakao/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // 사용자 관련 엔드포인트
  static const String user = '/user';
  
  // 주식 관련 엔드포인트
  static const String stock = '/stock';
  
  // 거래 관련 엔드포인트
  static const String trading = '/trading';
}

