import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class EnvConfig {
  static bool _initialized = false;

  /// 환경 변수 초기화
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await dotenv.load(fileName: "assets/env/.env");
      _initialized = true;
      logger.i('환경 변수 로드 완료');
    } catch (e) {
      logger.e('환경 변수 로드 실패: $e');
      // 개발 환경에서는 기본값 사용
      if (kDebugMode) {
        logger.w('개발 모드: 기본값 사용');
        _initialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// 환경 변수 값 가져오기 (기본값 제공)
  static String getValue(String key) {
    if (!_initialized) {
      logger.w('환경 변수가 초기화되지 않음: $key, 기본값 사용');
      return _getDefaultValue(key);
    }

    // flutter_dotenv가 실제로 초기화되지 않은 경우 안전 가드
    if (!dotenv.isInitialized) {
      logger.w('dotenv 미초기화 상태 감지: $key, 기본값 사용');
      return _getDefaultValue(key);
    }

    try {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty) {
        logger.w('환경 변수 값이 없음: $key, 기본값 사용');
        return _getDefaultValue(key);
      }
      return value;
    } catch (e) {
      logger.w('환경 변수 접근 실패: $key, 기본값 사용');
      return _getDefaultValue(key);
    }
  }

  /// 기본값 제공
  static String _getDefaultValue(String key) {
    switch (key) {
      case 'KAKAO_NATIVE_APP_KEY':
        return '2fd4280cde76fda045bf055db5875e86';
      case 'BACKEND_URL':
        return 'https://api.qbit.o-r.kr';
      case 'APP_NAME':
        return 'QBit';
      case 'APP_DESCRIPTION':
        return 'QBIT Mobile App - iOS/Android';
      case 'BACKEND_API_VERSION':
        return 'v1';
      case 'DEBUG_MODE':
        return 'true';
      case 'ENVIRONMENT':
        return 'development';
      case 'LOG_LEVEL':
        return 'info';
      default:
        return '';
    }
  }

  /// 필수 환경 변수 값 가져오기 (값이 없으면 예외 발생)
  static String getRequiredValue(String key) {
    if (!_initialized) {
      throw Exception('환경 변수가 초기화되지 않음: $key');
    }

    if (!dotenv.isInitialized) {
      throw Exception('dotenv가 초기화되지 않음: $key');
    }

    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('필수 환경 변수가 설정되지 않음: $key');
    }
    
    return value;
  }

  /// 백엔드 API 설정
  static String get backendUrl => getValue('BACKEND_URL');

  /// 카카오 로그인 설정 (네이티브 앱 키만 필요)
  static String get kakaoNativeAppKey => getValue('KAKAO_NATIVE_APP_KEY');

  /// 앱 설정
  static String get appName => getValue('APP_NAME');
  static String get appDescription => getValue('APP_DESCRIPTION');

  /// 환경 변수 초기화 상태 확인
  static bool get isInitialized => _initialized;

  /// 모든 환경 변수 출력 (디버그용)
  static void printAllEnvVars() {
    if (!_initialized) {
      logger.w('환경 변수가 초기화되지 않음');
      return;
    }
    
    logger.i('=== 환경 변수 목록 ===');
    dotenv.env.forEach((key, value) {
      // 민감한 정보는 마스킹
      if (key.toLowerCase().contains('key') || key.toLowerCase().contains('secret')) {
        logger.i('$key: ${value.substring(0, 8)}...');
      } else {
        logger.i('$key: $value');
      }
    });
    logger.i('==================');
  }
}
