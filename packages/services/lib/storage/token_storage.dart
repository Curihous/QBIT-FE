import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // 키 상수
  static const String _accessTokenKey = 'access_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  /// JWT 액세스 토큰 저장
  static Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      logger.i('액세스 토큰 저장 완료');
    } catch (e) {
      logger.e('액세스 토큰 저장 실패: $e');
      rethrow;
    }
  }

  /// JWT 액세스 토큰 조회
  static Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        logger.i('액세스 토큰 조회 완료');
      } else {
        logger.w('저장된 액세스 토큰 없음');
      }
      return token;
    } catch (e) {
      logger.e('액세스 토큰 조회 실패: $e');
      return null;
    }
  }

  /// 토큰 만료 시간 저장
  static Future<void> saveTokenExpiry(int expiresIn) async {
    try {
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiryTime.toIso8601String(),
      );
      logger.i('토큰 만료 시간 저장 완료: $expiryTime');
    } catch (e) {
      logger.e('토큰 만료 시간 저장 실패: $e');
      rethrow;
    }
  }

  /// 토큰 만료 여부 확인
  static Future<bool> isTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) {
        logger.w('저장된 토큰 만료 시간 없음');
        return true;
      }

      final expiryTime = DateTime.parse(expiryStr);
      final isExpired = DateTime.now().isAfter(expiryTime);
      
      logger.i('토큰 만료 여부: $isExpired');
      return isExpired;
    } catch (e) {
      logger.e('토큰 만료 여부 확인 실패: $e');
      return true;
    }
  }

  /// 사용자 ID 저장
  static Future<void> saveUserId(int userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId.toString());
      logger.i('사용자 ID 저장 완료: $userId');
    } catch (e) {
      logger.e('사용자 ID 저장 실패: $e');
      rethrow;
    }
  }

  /// 사용자 ID 조회
  static Future<int?> getUserId() async {
    try {
      final userIdStr = await _storage.read(key: _userIdKey);
      if (userIdStr != null) {
        final userId = int.tryParse(userIdStr);
        logger.i('사용자 ID 조회 완료: $userId');
        return userId;
      }
      logger.w('저장된 사용자 ID 없음');
      return null;
    } catch (e) {
      logger.e('사용자 ID 조회 실패: $e');
      return null;
    }
  }

  /// 모든 토큰 및 사용자 정보 삭제
  static Future<void> clearAll() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _userIdKey);
      logger.i('모든 토큰 및 사용자 정보 삭제 완료');
    } catch (e) {
      logger.e('토큰 삭제 실패: $e');
      rethrow;
    }
  }

  /// 토큰 존재 여부 확인
  static Future<bool> hasToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      logger.e('토큰 존재 여부 확인 실패: $e');
      return false;
    }
  }
}

