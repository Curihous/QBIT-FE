import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/google_auth_service.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/api/order_websocket_service.dart';
import 'package:qbit_services/models/auth_models.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
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
  
  /// 오래된 토큰 감지 및 삭제
  static Future<void> checkAndClearOldTokens() async {
    try {
      final token = await TokenService.getAccessToken();
      if (token != null) {
        // JWT 토큰 디코딩
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final paddedPayload = payload.padRight((payload.length + 3) & ~3, '=');
          final decodedBytes = base64Url.decode(paddedPayload);
          final decodedPayload = utf8.decode(decodedBytes);
          final payloadJson = json.decode(decodedPayload);
          
          // 토큰 만료 확인
          if (payloadJson['exp'] != null) {
            final expTimestamp = payloadJson['exp'] as int;
            final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
            final now = DateTime.now();
            final timeLeft = expDate.difference(now);
            
            if (timeLeft.isNegative) {
              logger.w('⚠️ 만료된 토큰 발견 - 삭제 중...');
              await TokenService.clearAllTokens();
            }
          }
        }
      }
    } catch (e) {
      logger.e('토큰 확인 중 오류: $e');
    }
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

    // 인터셉터 추가 (요청/응답 로그 활성화)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
      logPrint: (obj) => logger.i(obj),
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
                    
                    logger.i('개발 모드 백엔드 토큰 재발급 성공 - 요청 재시도');
                    final newToken = await _getAccessToken();
                    if (newToken != null) {
                      logger.i('새 토큰으로 요청 재시도: ${newToken.substring(0, 20)}...');
                      error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                      final retryResponse = await _refreshDio.fetch(error.requestOptions);
                      _retriedRequests.remove(requestKey);
                      handler.resolve(retryResponse);
                      return;
                    }
                  }
                }
                logger.w('개발 모드: 카카오 토큰으로 백엔드 토큰 재발급 실패');
              } else {
                logger.w('개발 모드: TokenService에 카카오 토큰 없음 - 재로그인 필요');
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
                
                try {
                  // 카카오 SDK에서 사용자 정보 조회 (자동 토큰 갱신 포함)
                  final user = await UserApi.instance.me();
                  final token = await TokenManagerProvider.instance.manager.getToken();
                  
                  if (token?.accessToken != null) {
                    logger.i('카카오 SDK에서 토큰 갱신 성공 - 백엔드 토큰 재발급 시도');
                    
                    final backendResult = await AuthApiService.kakaoLogin(
                      kakaoAccessToken: token!.accessToken,
                      userId: user.id.toString(),
                      nickname: user.kakaoAccount?.profile?.nickname ?? '',
                      email: user.kakaoAccount?.email ?? '',
                    );
                    
                    if (backendResult != null) {
                      final response = KakaoLoginResponse.fromJson(backendResult);
                    if (response.accessToken != null) {
                      logger.i('새 토큰 저장 시작: ${response.accessToken!.substring(0, 20)}...');
                      await TokenService.saveAccessToken(response.accessToken!);
                      logger.i('새 토큰 저장 완료');
                      
                      // 저장 완료를 위한 짧은 지연
                      await Future.delayed(const Duration(milliseconds: 100));
                      
                      logger.i('카카오 백엔드 토큰 재발급 성공 - 요청 재시도');
                      final newToken = await _getAccessToken();
                      logger.i('저장된 토큰 조회 결과: ${newToken != null ? '성공' : '실패'}');
                      if (newToken != null) {
                        logger.i('새 토큰으로 요청 재시도: ${newToken.substring(0, 20)}...');
                        error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                        logger.i('재시도 요청 헤더 설정 완료');
                        try {
                          final retryResponse = await _refreshDio.fetch(error.requestOptions);
                          logger.i('재시도 요청 성공');
                          
                          // WebSocket 재연결
                          await OrderWebSocketService.instance.reconnectWithNewToken();
                          
                          _retriedRequests.remove(requestKey);
                          handler.resolve(retryResponse);
                          return;
                        } catch (retryError) {
                          logger.e('재시도 요청 실패: $retryError');
                          if (retryError is DioException) {
                            logger.e('재시도 요청 상태코드: ${retryError.response?.statusCode}');
                            logger.e('재시도 요청 응답: ${retryError.response?.data}');
                          }
                          rethrow;
                        }
                      } else {
                        logger.e('저장된 토큰을 조회할 수 없음');
                      }
                    }
                    }
                  }
                } on KakaoException catch (e) {
                  if (e.isInvalidTokenError()) {
                    logger.e('카카오 토큰 무효. 재로그인 필요.');
                  } else {
                    logger.e('카카오 토큰 갱신 실패: $e');
                  }
                } catch (e) {
                  logger.e('카카오 토큰 갱신 중 오류: $e');
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
                      
                      // 저장 완료를 위한 짧은 지연
                      await Future.delayed(const Duration(milliseconds: 100));
                      
                      logger.i('구글 백엔드 토큰 재발급 성공 - 요청 재시도');
                      final newToken = await _getAccessToken();
                      if (newToken != null) {
                        logger.i('새 토큰으로 요청 재시도: ${newToken.substring(0, 20)}...');
                        error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                        final retryResponse = await _refreshDio.fetch(error.requestOptions);
                        
                        // WebSocket 재연결
                        await OrderWebSocketService.instance.reconnectWithNewToken();
                        
                        _retriedRequests.remove(requestKey);
                        handler.resolve(retryResponse);
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
            
            // 모든 토큰 재발급 시도가 실패한 경우 공통 처리
            _tokenExpiredController.add(null);
            handler.next(error);
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
          
      if (token != null) {
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
                logger.w('⚠️ 토큰이 만료되었습니다 - null 반환');
                return null; // 만료된 토큰은 null 반환
              } else {
                logger.i('✅ 토큰 유효 - ${timeLeft.inMinutes}분 남음');
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
