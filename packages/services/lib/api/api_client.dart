import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/models/auth_models.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'dart:convert';
import 'dart:async';

final logger = Logger();

class ApiClient {
  static late Dio _dio;
  static final StreamController<void> _tokenExpiredController = StreamController<void>.broadcast();
  
  static String get baseUrl {
    try {
      final envUrl = EnvConfig.backendUrl;
      if (envUrl.isNotEmpty) {
        return envUrl;
      }
    } catch (e) {
      logger.w('환경 변수에서 백엔드 URL을 가져올 수 없음: $e');
    }
    // 환경 변수가 없으면 기본값 사용
    return 'https://api.qbit.o-r.kr';
  }
  
  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      },
    ));

    // 인터셉터 추가 (에러만 표시)
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: true,
      requestHeader: false,
      responseHeader: false,
      logPrint: (obj) => logger.d(obj),
    ));

    // UTF-8 인코딩 인터셉터 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 요청 데이터 UTF-8 인코딩
        if (options.data is String) {
          options.data = utf8.encode(options.data);
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // 응답 데이터 UTF-8 디코딩
        if (response.data is String) {
          try {
            response.data = utf8.decode(response.data.codeUnits);
          } catch (e) {
            logger.w('UTF-8 디코딩 실패: $e');
          }
        }
        handler.next(response);
      },
    ));

    // 토큰 인터셉터 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 토큰이 있으면 헤더에 추가
        final token = await _getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          logger.i('토큰 추가됨: ${options.uri}');
        } else {
          logger.w('토큰 없음: ${options.uri}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 에러 시 카카오 토큰 기반 백엔드 토큰 재발급 시도
        if (error.response?.statusCode == 401) {
          logger.w('401 에러 발생 - 카카오 토큰 기반 백엔드 토큰 재발급 시도');
          
          try {
            // 1. 카카오 토큰 상태 확인
            final hasKakaoToken = await KakaoAuthService.hasToken();
            if (hasKakaoToken) {
              final tokenInfo = await KakaoAuthService.getTokenInfo();
              if (tokenInfo != null && !tokenInfo['isExpired']) {
                logger.i('카카오 토큰 유효 - 백엔드 토큰 재발급 시도');
                
                // 2. 카카오 사용자 정보 조회
                final kakaoUser = await KakaoAuthService.getCurrentUser();
                if (kakaoUser != null) {
                  final kakaoAccessToken = await TokenService.getKakaoAccessToken();
                  if (kakaoAccessToken != null) {
                    // 3. 카카오 사용자 정보로 백엔드 토큰 재발급
                    final backendResult = await AuthApiService.kakaoLogin(
                      kakaoAccessToken: kakaoAccessToken,
                      userId: kakaoUser['id'].toString(),
                      nickname: kakaoUser['nickname'] ?? '',
                      email: kakaoUser['email'] ?? '',
                    );
                    
                    if (backendResult != null) {
                      final response = KakaoLoginResponse.fromJson(backendResult);
                      if (response.accessToken != null) {
                        // 4. 새 백엔드 토큰 저장 후 요청 재시도
                        await TokenService.saveAccessToken(response.accessToken!);
                        
                        logger.i('백엔드 토큰 재발급 성공 - 요청 재시도');
                        final newToken = await _getAccessToken();
                        if (newToken != null) {
                          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                          final response = await _dio.fetch(error.requestOptions);
                          handler.resolve(response);
                          return;
                        }
                      }
                    }
                  }
                }
              } else {
                logger.w('카카오 토큰 만료 - 재로그인 필요');
              }
            } else {
              logger.w('카카오 토큰 없음 - 재로그인 필요');
            }
            
            // 5. 실패 시 로그인 화면으로 이동
            _tokenExpiredController.add(null);
          } catch (e) {
            logger.e('토큰 갱신 중 오류: $e');
            _tokenExpiredController.add(null);
          }
        }
        handler.next(error);
      },
    ));
  }

  static Dio get instance => _dio;
  static Stream<void> get onTokenExpired => _tokenExpiredController.stream;

  // 디버깅용 토큰 상태 확인
  static Future<void> debugTokenStatus() async {
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      final kakaoToken = await storage.read(key: 'kakao_access_token');
      
      logger.i('=== 토큰 상태 디버그 ===');
      logger.i('액세스 토큰: ${accessToken != null ? "존재 (길이: ${accessToken.length})" : "없음"}');
      logger.i('리프레시 토큰: ${refreshToken != null ? "존재 (길이: ${refreshToken.length})" : "없음"}');
      logger.i('카카오 토큰: ${kakaoToken != null ? "존재 (길이: ${kakaoToken.length})" : "없음"}');
      
      if (accessToken != null) {
        logger.i('액세스 토큰 시작: ${accessToken.substring(0, accessToken.length > 30 ? 30 : accessToken.length)}...');
      }
      logger.i('==================');
    } catch (error) {
      logger.e('토큰 상태 확인 실패: $error');
    }
  }

  // 토큰 관리 메서드들
  static Future<String?> _getAccessToken() async {
    try {
      // 백엔드 토큰으로 복구
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      logger.i('액세스 토큰 조회: ${token != null ? "존재" : "없음"}');
      if (token != null) {
        logger.i('토큰 길이: ${token.length}');
        logger.i('토큰 시작: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        
        // JWT 토큰 디코딩하여 만료 시간 확인
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            // payload 부분 디코딩
            final payload = parts[1];
            // Base64 패딩 추가
            final paddedPayload = payload.padRight((payload.length + 3) & ~3, '=');
            final decodedBytes = base64Url.decode(paddedPayload);
            final decodedPayload = utf8.decode(decodedBytes);
            final payloadJson = json.decode(decodedPayload);
            
            if (payloadJson['exp'] != null) {
              final expTimestamp = payloadJson['exp'] as int;
              final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
              final now = DateTime.now();
              final timeLeft = expDate.difference(now);
              
              logger.i('토큰 만료 시간: ${expDate.toIso8601String()}');
              logger.i('현재 시간: ${now.toIso8601String()}');
              logger.i('남은 시간: ${timeLeft.inMinutes}분 ${timeLeft.inSeconds % 60}초');
              logger.i('토큰 만료 여부: ${timeLeft.isNegative ? "만료됨" : "유효함"}');
              
              if (timeLeft.isNegative) {
                logger.w('⚠️ 토큰이 만료되었습니다! 재로그인이 필요합니다.');
                return null; // 만료된 토큰은 null 반환
              } else {
                logger.i('✅ 토큰이 유효합니다. ${timeLeft.inMinutes}분 남음');
              }
            } else {
              logger.i('토큰에 만료 시간 정보가 없습니다');
            }
          }
        } catch (e) {
          logger.w('토큰 디코딩 실패: $e');
        }
      }
      return token;
    } catch (error) {
      logger.e('액세스 토큰 조회 실패: $error');
      return null;
    }
  }


}
