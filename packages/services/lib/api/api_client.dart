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
          logger.w('401 에러 발생 - 토큰 재발급 시도');
          
          try {
            // 환경변수로 개발/프로덕션 플로우 구분
            final useDevLogin = EnvConfig.useDevLogin;
            
            if (useDevLogin) {
              // ========== 개발 모드: TokenService에 저장된 .env 토큰 사용 ==========
              logger.i('개발 모드: TokenService 토큰 사용');
              
              final kakaoAccessToken = await TokenService.getKakaoAccessToken();
              final kakaoUserId = await TokenService.getKakaoUserId();
              
              if (kakaoAccessToken != null && kakaoUserId != null) {
                logger.i('TokenService에서 카카오 토큰 발견 - 백엔드 토큰 재발급 시도');
                
                final backendResult = await AuthApiService.kakaoLogin(
                  kakaoAccessToken: kakaoAccessToken,
                  userId: kakaoUserId,
                  nickname: '',
                  email: '',
                );
                
                if (backendResult != null) {
                  final response = KakaoLoginResponse.fromJson(backendResult);
                  if (response.accessToken != null) {
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
              
              // 개발 모드에서 토큰이 없으면 재로그인 필요
              logger.w('개발 모드: 토큰 없음 - 재로그인 필요');
              _tokenExpiredController.add(null);
              handler.next(error);
              return;
              
            } else {
              // ========== 프로덕션 모드: Kakao SDK 사용 ==========
              logger.i('프로덕션 모드: Kakao SDK 사용');
              
              final hasKakaoToken = await KakaoAuthService.hasToken();
              if (!hasKakaoToken) {
                logger.w('Kakao SDK 토큰 없음 - 재로그인 필요');
                _tokenExpiredController.add(null);
                handler.next(error);
                return;
              }
              
              final tokenInfo = await KakaoAuthService.getTokenInfo();
              if (tokenInfo == null) {
                logger.w('Kakao SDK 토큰 정보 조회 실패 - 재로그인 필요');
                _tokenExpiredController.add(null);
                handler.next(error);
                return;
              }
              
              if (tokenInfo['isExpired']) {
                logger.w('Kakao SDK 토큰 만료 - 재로그인 필요');
                _tokenExpiredController.add(null);
                handler.next(error);
                return;
              }
              
              // Kakao SDK 토큰이 유효하면 백엔드 토큰 재발급
              logger.i('Kakao SDK 토큰 유효 - 백엔드 토큰 재발급 시도');
              
              final kakaoUser = await KakaoAuthService.getCurrentUser();
              if (kakaoUser != null) {
                final kakaoAccessToken = await TokenService.getKakaoAccessToken();
                if (kakaoAccessToken != null) {
                  final backendResult = await AuthApiService.kakaoLogin(
                    kakaoAccessToken: kakaoAccessToken,
                    userId: kakaoUser['id'].toString(),
                    nickname: kakaoUser['nickname'] ?? '',
                    email: kakaoUser['email'] ?? '',
                  );
                  
                  if (backendResult != null) {
                    final response = KakaoLoginResponse.fromJson(backendResult);
                    if (response.accessToken != null) {
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
              
              logger.w('프로덕션 모드: 백엔드 토큰 재발급 실패');
            }
          } catch (e) {
            logger.e('토큰 갱신 중 오류: $e');
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
      
      // 테스트단계에서만 쓸거니까 리뷰에서 제외
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
      // 개발 모드일 때는 TokenService 사용 (동일한 Storage 인스턴스)
      // 프로덕션일 때는 직접 FlutterSecureStorage 사용
      final token = EnvConfig.useDevLogin 
          ? await TokenService.getAccessToken()
          : await const FlutterSecureStorage().read(key: 'access_token');
          
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
              
              if (timeLeft.isNegative) {
                logger.w('⚠️ 토큰이 만료되었습니다');
              } else {
                logger.i('✅ 토큰 유효: ${timeLeft.inMinutes}분 남음');
              }
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
