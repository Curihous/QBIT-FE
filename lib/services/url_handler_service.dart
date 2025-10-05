import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final logger = Logger();

class UrlHandlerService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _isNewUserKey = 'is_new_user';

  /// URL 스킴 처리
  static Future<void> handleIncomingUrl(String? url) async {
    if (url == null) return;

    logger.i('🔗 받은 URL: $url');

    // localhost:3000/oauth?accessToken=...&userId=...&isNewUser=... 형태인지 확인
    if (url.contains('localhost:3000/oauth')) {
      await _handleOAuthCallback(url);
    }
  }

  /// OAuth 콜백 처리
  static Future<void> _handleOAuthCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // URL 파라미터 추출
      final accessToken = uri.queryParameters['accessToken'];
      final userId = uri.queryParameters['userId'];
      final isNewUser = uri.queryParameters['isNewUser'];
      final expiresIn = uri.queryParameters['expiresIn'];

      if (accessToken != null && userId != null) {
        // 토큰 저장
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(key: _userIdKey, value: userId);
        
        if (isNewUser != null) {
          await _storage.write(key: _isNewUserKey, value: isNewUser);
        }

        logger.i('✅ OAuth 콜백 처리 완료');
        logger.i('✅ Access Token 저장됨');
        logger.i('✅ User ID: $userId');
        logger.i('✅ 신규 사용자: $isNewUser');
        
        // TODO: 홈 화면으로 네비게이션
        // context.go('/home');
      } else {
        logger.e('❌ 필수 파라미터 누락: accessToken=$accessToken, userId=$userId');
      }
    } catch (e) {
      logger.e('❌ OAuth 콜백 처리 실패: $e');
    }
  }

  /// 저장된 토큰 확인
  static Future<bool> hasValidToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// 저장된 사용자 정보 가져오기
  static Future<Map<String, String?>> getUserInfo() async {
    return {
      'accessToken': await _storage.read(key: _accessTokenKey),
      'userId': await _storage.read(key: _userIdKey),
      'isNewUser': await _storage.read(key: _isNewUserKey),
    };
  }

  /// 로그아웃 (토큰 삭제)
  static Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _isNewUserKey);
    logger.i('✅ 로그아웃 완료 (토큰 삭제)');
  }
}
