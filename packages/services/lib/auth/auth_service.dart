import 'package:logger/logger.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';

final logger = Logger();

class AuthService {



  /// 현재 사용자 정보 조회
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      return await KakaoAuthService.getSimpleUserInfo();
    } catch (error) {
      logger.e('사용자 정보 조회 실패: $error');
      return null;
    }
  }

  /// 로그아웃
  static Future<bool> logout() async {
    try {
      // 카카오 SDK 로그아웃
      await KakaoAuthService.logout();
      logger.i('로그아웃 성공');
      return true;
    } catch (error) {
      logger.e('로그아웃 실패: $error');
      return false;
    }
  }


  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      // 카카오 SDK로 토큰 존재 여부 확인
      return await KakaoAuthService.hasToken();
    } catch (e) {
      logger.e('로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// 액세스 토큰 정보 조회
  static Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      return await KakaoAuthService.getTokenInfo();
    } catch (error) {
      logger.e('토큰 정보 조회 실패: $error');
      return null;
    }
  }

}
