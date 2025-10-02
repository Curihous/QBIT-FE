import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get kakaoNativeAppKey => 
      dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  
  static String get kakaoRestApiKey => 
      dotenv.env['KAKAO_REST_API_KEY'] ?? '';
  
  static String get baseUrl => 
      dotenv.env['BASE_URL'] ?? 'http://localhost:3000/api/v1';
  
  static String get backendUrl => 
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000';
}
