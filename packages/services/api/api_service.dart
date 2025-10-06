import 'package:dio/dio.dart' hide Options;
import 'package:dio/src/options.dart' as dio_options;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

final logger = Logger();

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  late final Dio _dio;
  late final FlutterSecureStorage _storage;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _storage = const FlutterSecureStorage();
    _setupInterceptors();
  }

  // 웹 환경에서 안전한 토큰 읽기
  Future<String?> _readToken(String key) async {
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
  Future<void> _writeToken(String key, String value) async {
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
  Future<void> _deleteToken(String key) async {
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

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 요청 시 액세스 토큰 자동 추가
          final token = await _readToken(_accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 에러 시 토큰 갱신 시도
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // 토큰 갱신 성공 시 원래 요청 재시도
              final token = await _readToken(_accessTokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 카카오 인가 코드를 백엔드로 전송
  Future<Map<String, dynamic>?> sendKakaoCodeToBackend(String code) async {
    try {
      final response = await _dio.post(
        '/login/oauth2/code/kakao',
        data: {
          'code': code,
        },
        options: dio_options.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // JWT 토큰 저장
        if (data['accessToken'] != null) {
          await _writeToken(_accessTokenKey, data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _writeToken(_refreshTokenKey, data['refreshToken']);
        }
        
        logger.i('백엔드 로그인 성공: ${data['userId']}');
        return data;
      }
    } catch (error) {
      logger.e('백엔드 로그인 실패: $error');
      if (error is DioException) {
        logger.e('응답 상태: ${error.response?.statusCode}');
        logger.e('응답 데이터: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('요청 데이터: ${error.requestOptions.data}');
      }
    }
    return null;
  }

  /// 카카오 사용자 정보를 백엔드로 전송 (REST API 방식)
  Future<Map<String, dynamic>?> sendKakaoUserInfoToBackend(
    String kakaoAccessToken, 
    Map<String, dynamic> kakaoUserInfo
  ) async {
    try {
      final response = await _dio.post(
        '/auth/kakao',
        data: {
          'kakaoAccessToken': kakaoAccessToken,
          'kakaoUserInfo': kakaoUserInfo,
        },
        options: dio_options.Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // JWT 토큰 저장
        if (data['accessToken'] != null) {
          await _writeToken(_accessTokenKey, data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _writeToken(_refreshTokenKey, data['refreshToken']);
        }
        
        logger.i('백엔드 로그인 성공: ${data['userId']}');
        return data;
      }
    } catch (error) {
      logger.e('백엔드 로그인 실패: $error');
      if (error is DioException) {
        logger.e('응답 상태: ${error.response?.statusCode}');
        logger.e('응답 데이터: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('요청 데이터: ${error.requestOptions.data}');
      }
    }
    return null;
  }

  /// 토큰 갱신
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _readToken(_refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh-tokens', // 백엔드 API에 맞춰 수정
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _writeToken(_accessTokenKey, data['accessToken']);
        logger.i('토큰 갱신 성공');
        return true;
      }
    } catch (error) {
      logger.e('토큰 갱신 실패: $error');
    }
    return false;
  }

  /// 현재 사용자 정보 조회
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (error) {
      logger.e('사용자 정보 조회 실패: $error');
    }
    return null;
  }

  /// 로그아웃
  Future<bool> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      if (response.statusCode == 200) {
        // 로컬 토큰 삭제
        await _deleteToken(_accessTokenKey);
        await _deleteToken(_refreshTokenKey);
        logger.i('로그아웃 성공');
        return true;
      }
    } catch (error) {
      logger.e('로그아웃 실패: $error');
    }
    return false;
  }

  /// 저장된 액세스 토큰 확인
  Future<String?> getAccessToken() async {
    return await _readToken(_accessTokenKey);
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}
