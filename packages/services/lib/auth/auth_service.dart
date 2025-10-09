import 'package:logger/logger.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/storage/token_storage.dart';

final logger = Logger();

class AuthService {
  static final AuthApiService _authApiService = AuthApiService();

  /// 카카오 로그인 (전체 플로우)
  /// 1. 카카오 SDK로 카카오 액세스 토큰 획득
  /// 2. 백엔드로 카카오 액세스 토큰 전송
  /// 3. 백엔드에서 받은 JWT 토큰 저장
  static Future<Map<String, dynamic>> login() async {
    try {
      logger.i('로그인 플로우 시작');
      
      // 1. 카카오 SDK로 로그인하여 카카오 액세스 토큰 획득
      final kakaoResult = await KakaoAuthService.login();
      
      if (kakaoResult?['success'] != true) {
        logger.e('카카오 SDK 로그인 실패');
        return kakaoResult ?? {'success': false, 'error': '카카오 로그인 실패'};
      }
      
      final kakaoAccessToken = kakaoResult?['accessToken'];
      if (kakaoAccessToken == null || kakaoAccessToken.isEmpty) {
        logger.e('카카오 액세스 토큰을 받지 못함');
        return {'success': false, 'error': '카카오 액세스 토큰을 받지 못했습니다'};
      }
      
      logger.i('카카오 SDK 로그인 성공, 백엔드로 전송');
      
      // 2. 백엔드로 카카오 액세스 토큰 전송
      final backendResult = await _authApiService.loginWithKakao(kakaoAccessToken);
      
      if (backendResult['success'] != true) {
        logger.e('백엔드 로그인 실패');
        return backendResult;
      }
      
      // 3. 백엔드에서 받은 JWT 토큰 및 사용자 정보 저장
      final jwtAccessToken = backendResult['accessToken'];
      final expiresIn = backendResult['expiresIn'];
      final userId = backendResult['userId'];
      
      await TokenStorage.saveAccessToken(jwtAccessToken);
      await TokenStorage.saveTokenExpiry(expiresIn);
      await TokenStorage.saveUserId(userId);
      
      logger.i('로그인 플로우 완료: userId=$userId, isNewUser=${backendResult['isNewUser']}');
      
      return backendResult;
    } catch (e, stack) {
      logger.e('로그인 플로우 중 예외 발생: $e\n$stack');
      return {'success': false, 'error': '로그인 중 오류가 발생했습니다'};
    }
  }

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
      // 1. 백엔드에 로그아웃 요청
      await _authApiService.logout();
      
      // 2. 로컬 JWT 토큰 삭제
      await TokenStorage.clearAll();
      
      // 3. 카카오 SDK 로그아웃
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
      // JWT 토큰 존재 여부 확인
      final hasToken = await TokenStorage.hasToken();
      if (!hasToken) {
        logger.w('저장된 JWT 토큰 없음');
        return false;
      }
      
      // 토큰 만료 여부 확인
      final isExpired = await TokenStorage.isTokenExpired();
      if (isExpired) {
        logger.w('JWT 토큰 만료됨');
        return false;
      }
      
      return true;
    } catch (e) {
      logger.e('로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// JWT 액세스 토큰 조회
  static Future<String?> getAccessToken() async {
    try {
      return await TokenStorage.getAccessToken();
    } catch (error) {
      logger.e('액세스 토큰 조회 실패: $error');
      return null;
    }
  }

  /// 사용자 ID 조회
  static Future<int?> getUserId() async {
    try {
      return await TokenStorage.getUserId();
    } catch (error) {
      logger.e('사용자 ID 조회 실패: $error');
      return null;
    }
  }
}
