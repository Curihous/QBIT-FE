import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/api/api_service.dart';

final logger = Logger();

class AuthService {
  static final AuthApiService _authApiService = AuthApiService();
  static final UserApiService _userApiService = UserApiService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // 토큰 키 상수
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _isNewUserKey = 'is_new_user';

  // 웹 환경에서 안전한 토큰 읽기
  static Future<String?> _readToken(String key) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (e) {
        logger.e('웹 환경에서 토큰 읽기 실패: $e');
        return null;
      }
    } else {
      return await _storage.read(key: key);
    }
  }

  // 웹 환경에서 안전한 토큰 쓰기
  static Future<void> _writeToken(String key, String value) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (e) {
        logger.e('웹 환경에서 토큰 쓰기 실패: $e');
      }
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  // 웹 환경에서 안전한 토큰 삭제
  static Future<void> _deleteToken(String key) async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (e) {
        logger.e('웹 환경에서 토큰 삭제 실패: $e');
      }
    } else {
      await _storage.delete(key: key);
    }
  }

  /// URL 스킴 처리 (OAuth 콜백)
  static Future<void> handleIncomingUrl(String? url) async {
    if (url == null) return;

    logger.i('받은 URL: $url');

    // OAuth 콜백 URL 패턴 확인
    if (url.contains('api.qbit.o-r.kr/login/oauth2/code/kakao') ||
        url.contains('localhost:5000') ||
        url.contains('127.0.0.1:5000')) {
      await _handleOAuthCallback(url);
    }
  }

  /// OAuth 콜백 처리
  static Future<void> _handleOAuthCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      
      logger.i('OAuth 콜백 URL 분석:');
      logger.i('  전체 URL: $url');
      logger.i('  호스트: ${uri.host}');
      logger.i('  포트: ${uri.port}');
      logger.i('  경로: ${uri.path}');
      logger.i('  쿼리 파라미터: ${uri.queryParameters}');
      
      // 인가 코드 또는 JWT 토큰 파라미터 추출
      final code = uri.queryParameters['code'];
      final accessToken = uri.queryParameters['accessToken'];
      final userId = uri.queryParameters['userId'];
      final isNewUser = uri.queryParameters['isNewUser'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];
      final state = uri.queryParameters['state'];
      
      // 카카오 로그인 에러 확인
      if (error != null) {
        logger.e('KAKAO ERROR: $error');
        logger.e('ERROR DESCRIPTION: $errorDescription');
        logger.e('STATE: $state');
        return;
      }

      if (code != null) {
        // 인가 코드를 백엔드로 전송
        logger.i('인가 코드 받음: $code');
        await _sendCodeToBackend(code);
      } else if (accessToken != null && userId != null) {
        // JWT 토큰 저장 (백엔드에서 처리 완료 후)
        await _writeToken(_accessTokenKey, accessToken);
        await _writeToken(_userIdKey, userId);
        
        if (isNewUser != null) {
          await _writeToken(_isNewUserKey, isNewUser);
        }

        logger.i('OAuth 콜백 처리 완료');
        logger.i('Access Token 저장됨');
        logger.i('User ID: $userId');
        logger.i('신규 사용자: $isNewUser');
      } else {
        logger.e('필수 파라미터 누락: code=$code, accessToken=$accessToken, userId=$userId');
        logger.e('전체 쿼리 파라미터: ${uri.queryParameters}');
      }
    } catch (e) {
      logger.e('OAuth 콜백 처리 실패: $e');
    }
  }

  /// 인가 코드를 백엔드로 전송
  static Future<void> _sendCodeToBackend(String code) async {
    try {
      logger.i('인가 코드 처리 시작: $code');
      
      // 백엔드로 인가 코드 직접 전송
      final backendResult = await _authApiService.sendKakaoCodeToBackend(code);
      if (backendResult != null) {
        // 백엔드에서 받은 JWT 토큰 저장
        await _writeToken(_accessTokenKey, backendResult['accessToken']);
        await _writeToken(_userIdKey, backendResult['userId']);
        
        if (backendResult['isNewUser'] != null) {
          await _writeToken(_isNewUserKey, backendResult['isNewUser'].toString());
        }
        
        logger.i('로그인 완료: ${backendResult['userId']}');
      }
      
    } catch (e) {
      logger.e('인가 코드 처리 실패: $e');
    }
  }

  /// 카카오 사용자 정보를 백엔드로 전송
  static Future<Map<String, dynamic>?> sendKakaoUserInfoToBackend(
    String kakaoAccessToken, 
    Map<String, dynamic> kakaoUserInfo
  ) async {
    try {
      logger.i('백엔드로 카카오 사용자 정보 전송');
      logger.i('카카오 사용자 ID: ${kakaoUserInfo['id']}');
      logger.i('카카오 닉네임: ${kakaoUserInfo['kakao_account']?['profile']?['nickname']}');
      
      // 실제 백엔드 API 호출
      return await _authApiService.sendKakaoUserInfoToBackend(kakaoAccessToken, kakaoUserInfo);
      
    } catch (e) {
      logger.e('백엔드로 사용자 정보 전송 실패: $e');
      return null;
    }
  }

  /// 토큰 갱신
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _readToken(_refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _authApiService.refreshTokens(refreshToken);
      if (response != null) {
        await _writeToken(_accessTokenKey, response['accessToken']);
        logger.i('토큰 갱신 성공');
        return true;
      }
    } catch (error) {
      logger.e('토큰 갱신 실패: $error');
    }
    return false;
  }

  /// 현재 사용자 정보 조회
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = await _userApiService.getCurrentUser();
      return user?.toJson();
    } catch (error) {
      logger.e('사용자 정보 조회 실패: $error');
      return null;
    }
  }

  /// 로그아웃
  static Future<bool> logout() async {
    try {
      await _authApiService.logout();
      // 로컬 토큰 삭제
      await _deleteToken(_accessTokenKey);
      await _deleteToken(_refreshTokenKey);
      await _deleteToken(_userIdKey);
      await _deleteToken(_isNewUserKey);
      logger.i('로그아웃 성공');
      return true;
    } catch (error) {
      logger.e('로그아웃 실패: $error');
      return false;
    }
  }

  /// 저장된 액세스 토큰 확인
  static Future<String?> getAccessToken() async {
    return await _readToken(_accessTokenKey);
  }

  /// 저장된 사용자 정보 가져오기
  static Future<Map<String, String?>> getUserInfo() async {
    return {
      'accessToken': await _readToken(_accessTokenKey),
      'userId': await _readToken(_userIdKey),
      'isNewUser': await _readToken(_isNewUserKey),
    };
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// 유효한 토큰 확인
  static Future<bool> hasValidToken() async {
    return await isLoggedIn();
  }
}
