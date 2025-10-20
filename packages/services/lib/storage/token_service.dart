import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TokenService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 토큰 키 상수
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _kakaoAccessTokenKey = 'kakao_access_token';
  static const String _kakaoUserIdKey = 'kakao_user_id';

  /// 액세스 토큰 저장
  static Future<void> saveAccessToken(String token) async {
    try {
      logger.i('액세스 토큰 저장 시도: ${token.substring(0, 20)}...');
      await _storage.write(key: _accessTokenKey, value: token);
      logger.i('액세스 토큰 저장 완료');
    } catch (error) {
      logger.e('액세스 토큰 저장 실패: $error');
    }
  }

  /// 액세스 토큰 조회
  static Future<String?> getAccessToken() async {
    try {
      // 토큰 조회 로그 제거 (너무 많이 출력됨)
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null) {
        logger.w('저장된 액세스 토큰 없음');
      }
      return token;
    } catch (error) {
      logger.e('액세스 토큰 조회 실패: $error');
      return null;
    }
  }

  /// 리프레시 토큰 저장
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (error) {
      logger.e('리프레시 토큰 저장 실패: $error');
    }
  }

  /// 리프레시 토큰 조회
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      return token;
    } catch (error) {
      logger.e('리프레시 토큰 조회 실패: $error');
      return null;
    }
  }

  /// 카카오 액세스 토큰 저장
  static Future<void> saveKakaoAccessToken(String token) async {
    try {
      await _storage.write(key: _kakaoAccessTokenKey, value: token);
    } catch (error) {
      logger.e('카카오 액세스 토큰 저장 실패: $error');
    }
  }

  /// 카카오 액세스 토큰 조회
  static Future<String?> getKakaoAccessToken() async {
    try {
      final token = await _storage.read(key: _kakaoAccessTokenKey);
      if (token != null) {
        // 개발용 로그 (리뷰 시 무시)
        logger.i('🔍 카카오 액세스 토큰: $token');
      }
      return token;
    } catch (error) {
      logger.e('카카오 액세스 토큰 조회 실패: $error');
      return null;
    }
  }

  /// 카카오 사용자 ID 저장
  static Future<void> saveKakaoUserId(String userId) async {
    try {
      await _storage.write(key: _kakaoUserIdKey, value: userId);
      logger.i('카카오 사용자 ID 저장 완료');
    } catch (error) {
      logger.e('카카오 사용자 ID 저장 실패: $error');
    }
  }

  /// 카카오 사용자 ID 조회
  static Future<String?> getKakaoUserId() async {
    try {
      final userId = await _storage.read(key: _kakaoUserIdKey);
      logger.i('카카오 사용자 ID 조회: ${userId != null ? '존재' : '없음'}');
      return userId;
    } catch (error) {
      logger.e('카카오 사용자 ID 조회 실패: $error');
      return null;
    }
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      final accessToken = await getAccessToken();
      // 백엔드에서 refreshToken을 제공하지 않으므로 accessToken만 확인
      return accessToken != null;
    } catch (error) {
      logger.e('로그인 상태 확인 실패: $error');
      return false;
    }
  }

  /// 백엔드 토큰 존재 여부 확인
  static Future<bool> hasBackendToken() async {
    try {
      final accessToken = await getAccessToken();
      return accessToken != null;
    } catch (error) {
      logger.e('백엔드 토큰 확인 실패: $error');
      return false;
    }
  }

  /// 카카오 전용 세션인지 확인 (백엔드 액세스 토큰 없고 카카오 토큰만 있는 경우)
  static Future<bool> isKakaoOnlySession() async {
    try {
      final hasBackendAccess = await hasBackendToken();
      final hasKakaoToken = await getKakaoAccessToken() != null;
      
      // 백엔드 액세스 토큰이 없고 카카오 토큰만 있으면 카카오 전용 세션
      return !hasBackendAccess && hasKakaoToken;
    } catch (error) {
      logger.e('카카오 전용 세션 확인 실패: $error');
      return false;
    }
  }
  
  /// 모든 토큰 완전 삭제 (로컬 스토리지 초기화)
  static Future<void> clearAllTokens() async {
    try {
      logger.w('모든 토큰 삭제 시작...');
      
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _kakaoAccessTokenKey);
      await _storage.delete(key: _kakaoUserIdKey);
      await _storage.deleteAll();
      
      logger.i('모든 토큰 삭제 완료');
    } catch (error) {
      logger.e('토큰 삭제 실패: $error');
    }
  }
}
