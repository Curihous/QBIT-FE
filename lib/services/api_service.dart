import 'package:dio/dio.dart' hide Options;
import 'package:dio/src/options.dart' as dio_options;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ApiService {
  static const String baseUrl = 'https://api.qbit.o-r.kr';
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

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 요청 시 액세스 토큰 자동 추가
          final token = await _storage.read(key: _accessTokenKey);
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
              final token = await _storage.read(key: _accessTokenKey);
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

  /// 카카오 로그인 후 백엔드로 토큰 전송
  Future<Map<String, dynamic>?> sendKakaoTokenToBackend(String kakaoAccessToken) async {
    try {
      final response = await _dio.post(
        '/auth/kakao',
        data: {
          'accessToken': kakaoAccessToken,
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
          await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        }
        if (data['refreshToken'] != null) {
          await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
        }
        
        logger.i('✅ 백엔드 로그인 성공: ${data['userId']}');
        return data;
      }
    } catch (error) {
      logger.e('❌ 백엔드 로그인 실패: $error');
      if (error is DioException) {
        logger.e('❌ 응답 상태: ${error.response?.statusCode}');
        logger.e('❌ 응답 데이터: ${error.response?.data}');
        logger.e('❌ 요청 URL: ${error.requestOptions.uri}');
        logger.e('❌ 요청 데이터: ${error.requestOptions.data}');
      }
    }
    return null;
  }

  /// 토큰 갱신
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        logger.i('✅ 토큰 갱신 성공');
        return true;
      }
    } catch (error) {
      logger.e('❌ 토큰 갱신 실패: $error');
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
      logger.e('❌ 사용자 정보 조회 실패: $error');
    }
    return null;
  }

  /// 로그아웃
  Future<bool> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      if (response.statusCode == 200) {
        // 로컬 토큰 삭제
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
        logger.i('✅ 로그아웃 성공');
        return true;
      }
    } catch (error) {
      logger.e('❌ 로그아웃 실패: $error');
    }
    return false;
  }

  /// 저장된 액세스 토큰 확인
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}
