import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/google_auth_service.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/models/auth_models.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'dart:convert';
import 'dart:async';

final logger = Logger();

class ApiClient {
  static late Dio _dio;
  static late Dio _refreshDio;
  static final StreamController<void> _tokenExpiredController = StreamController<void>.broadcast();
  static final Set<String> _retriedRequests = {}; // 재시도한 요청 추적용
  
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

    // 토큰 재발급용 Dio 인스턴스 (인터셉터 없음)
    _refreshDio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8',
      },
    ));

    // 인터셉터 추가 (모든 로그 비활성화)
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      error: false,
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
          // 재시도 횟수 확인 (무한 루프 방지) - 요청 URL 기반
          final requestKey = '${error.requestOptions.method}:${error.requestOptions.uri.toString()}';
          if (_retriedRequests.contains(requestKey)) {
            logger.w('401 에러 - 이미 재시도했으므로 중단: $requestKey');
            _retriedRequests.remove(requestKey); // 추적 세트에서 제거
            _tokenExpiredController.add(null);
            handler.next(error);
            return;
          }
          
          // 재시도 추적에 추가
          _retriedRequests.add(requestKey);
          logger.w('401 에러 발생 - 토큰 재발급 시도: $requestKey');
          
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
                    
                    // 카카오 액세스 토큰 출력
                    logger.i('🔍 카카오 액세스 토큰: $kakaoAccessToken');
                    
                    logger.i('백엔드 토큰 재발급 성공 - 요청 재시도');
                    final newToken = await _getAccessToken();
                    if (newToken != null) {
                      error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                      
                      logger.i('🔍 실제 전송 헤더: ${error.requestOptions.headers}');
                      logger.i('🔍 Authorization 헤더: ${error.requestOptions.headers['Authorization']}');
                      try {
                        final retryResponse = await _refreshDio.fetch(error.requestOptions);
                        logger.i('✅ 토큰 재발급 후 요청 재시도 성공!');
                        handler.resolve(retryResponse);
                        return;
                      } catch (retryError) {
                        logger.e('❌ 토큰 재발급 후 요청 재시도 실패: $retryError');
                        logger.e('❌ 백엔드에서 유효한 토큰을 거부하고 있습니다!');
                      }
                    }
                  }
                }
              }
              
              // 개발 모드에서 토큰이 없으면 재로그인 필요
              logger.w('개발 모드: 토큰 없음 - 재로그인 필요');
              _retriedRequests.remove(requestKey); // 실패 시에도 제거
              _tokenExpiredController.add(null);
              handler.next(error);
              return;
              
            } else {
              // ========== 프로덕션 모드: 소셜 로그인(카카오/구글) 사용 ==========
              logger.i('프로덕션 모드: 소셜 로그인 토큰 확인');
              
              // 카카오 로그인인 경우
              final hasKakaoToken = await KakaoAuthService.hasToken();
              if (hasKakaoToken) {
                logger.i('카카오 로그인 감지 - 백엔드 토큰 재발급 시도');
                
                final kakaoAccessToken = await TokenService.getKakaoAccessToken();
                if (kakaoAccessToken != null) {
                  final userId = await TokenService.getKakaoUserId();
                  final backendResult = await AuthApiService.kakaoLogin(
                    kakaoAccessToken: kakaoAccessToken,
                    userId: userId ?? '',
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
                        logger.i('🔍 실제 전송 헤더: ${error.requestOptions.headers}');
                        logger.i('🔍 Authorization 헤더: ${error.requestOptions.headers['Authorization']}');
                        try {
                          final retryResponse = await _refreshDio.fetch(error.requestOptions);
                          logger.i('✅ 토큰 재발급 후 요청 재시도 성공!');
                          handler.resolve(retryResponse);
                          return;
                        } catch (retryError) {
                          logger.e('❌ 토큰 재발급 후 요청 재시도 실패: $retryError');
                          logger.e('❌ 백엔드에서 유효한 토큰을 거부하고 있습니다!');
                        }
                        return;
                      }
                    }
                  }
                }
                
                logger.w('카카오 토큰으로 백엔드 토큰 재발급 실패');
                _retriedRequests.remove(requestKey); // 실패 시에도 제거
                _tokenExpiredController.add(null);
                handler.next(error);
                return;
              }
              
              // 구글 로그인인 경우
              final hasGoogleToken = await GoogleAuthService.isSignedIn();
              if (hasGoogleToken) {
                logger.i('구글 로그인 감지 - 백엔드 토큰 재발급 시도');
                
                final googleUser = await GoogleAuthService.getCurrentUser();
                if (googleUser != null && googleUser['idToken'] != null) {
                  final backendResult = await AuthApiService.googleLogin(
                    googleIdToken: googleUser['idToken'],
                  );
                  
                  if (backendResult != null) {
                    final response = GoogleLoginResponse.fromJson(backendResult);
                    if (response.accessToken != null) {
                      await TokenService.saveAccessToken(response.accessToken!);
                      
                      logger.i('백엔드 토큰 재발급 성공 - 요청 재시도');
                      final newToken = await _getAccessToken();
                      if (newToken != null) {
                        error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                        logger.i('🔍 실제 전송 헤더: ${error.requestOptions.headers}');
                        logger.i('🔍 Authorization 헤더: ${error.requestOptions.headers['Authorization']}');
                        try {
                          final retryResponse = await _refreshDio.fetch(error.requestOptions);
                          logger.i('✅ 토큰 재발급 후 요청 재시도 성공!');
                          handler.resolve(retryResponse);
                          return;
                        } catch (retryError) {
                          logger.e('❌ 토큰 재발급 후 요청 재시도 실패: $retryError');
                          logger.e('❌ 백엔드에서 유효한 토큰을 거부하고 있습니다!');
                        }
                        return;
                      }
                    }
                  }
                }
                
                logger.w('구글 토큰으로 백엔드 토큰 재발급 실패');
                _retriedRequests.remove(requestKey); // 실패 시에도 제거
                _tokenExpiredController.add(null);
                handler.next(error);
                return;
              }
              
              logger.w('프로덕션 모드: 소셜 로그인 토큰 없음 - 재로그인 필요');
              _retriedRequests.remove(requestKey); // 실패 시에도 제거
            }
          } catch (e) {
            logger.e('토큰 갱신 중 오류: $e');
            if (error.response?.statusCode == 401) {
              final requestKey = '${error.requestOptions.method}:${error.requestOptions.uri.toString()}';
              _retriedRequests.remove(requestKey); // 예외 발생 시에도 제거
            }
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
      final accessToken = await TokenService.getAccessToken();
      final refreshToken = await TokenService.getRefreshToken();
      final kakaoToken = await TokenService.getKakaoAccessToken();
      
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
      // TokenService 사용
      final token = await TokenService.getAccessToken();
          
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
