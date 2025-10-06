import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:qbit_core/constants/app_constants.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';

/// 안전한 저장소 서비스 (토큰 등 민감한 정보)
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 액세스 토큰 저장
  static Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: AppConstants.accessTokenKey, value: token);
    } catch (e) {
      throw StorageException(
        message: '액세스 토큰 저장 실패: $e',
        key: AppConstants.accessTokenKey,
      );
    }
  }

  /// 액세스 토큰 조회
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw StorageException(
        message: '액세스 토큰 조회 실패: $e',
        key: AppConstants.accessTokenKey,
      );
    }
  }

  /// 리프레시 토큰 저장
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (e) {
      throw StorageException(
        message: '리프레시 토큰 저장 실패: $e',
        key: AppConstants.refreshTokenKey,
      );
    }
  }

  /// 리프레시 토큰 조회
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw StorageException(
        message: '리프레시 토큰 조회 실패: $e',
        key: AppConstants.refreshTokenKey,
      );
    }
  }

  /// 모든 토큰 삭제
  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw StorageException(
        message: '토큰 삭제 실패: $e',
      );
    }
  }

  /// 모든 데이터 삭제
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException(
        message: '모든 데이터 삭제 실패: $e',
      );
    }
  }
}

/// 일반 저장소 서비스 (설정 등 비민감 정보)
class LocalStorageService {
  /// 사용자 정보 저장
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userInfoKey, userInfo.toString());
    } catch (e) {
      throw StorageException(
        message: '사용자 정보 저장 실패: $e',
        key: AppConstants.userInfoKey,
      );
    }
  }

  /// 사용자 정보 조회
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString(AppConstants.userInfoKey);
      if (userInfoString == null) return null;
      
      // 실제 구현에서는 JSON 파싱을 사용해야 함
      return {}; // 임시 구현
    } catch (e) {
      throw StorageException(
        message: '사용자 정보 조회 실패: $e',
        key: AppConstants.userInfoKey,
      );
    }
  }

  /// 첫 실행 여부 확인
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.isFirstLaunchKey) == null;
    } catch (e) {
      throw StorageException(
        message: '첫 실행 여부 확인 실패: $e',
        key: AppConstants.isFirstLaunchKey,
      );
    }
  }

  /// 첫 실행 완료 표시
  static Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.isFirstLaunchKey, 'false');
    } catch (e) {
      throw StorageException(
        message: '첫 실행 완료 표시 실패: $e',
        key: AppConstants.isFirstLaunchKey,
      );
    }
  }

  /// 모든 로컬 데이터 삭제
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw StorageException(
        message: '로컬 데이터 삭제 실패: $e',
      );
    }
  }
}
