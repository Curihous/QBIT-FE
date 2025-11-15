import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:qbit_core/config/app_config.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_shared/main.dart';
import 'package:qbit_services/api/api_client.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/order_websocket_service.dart';
import 'package:qbit_services/auth/google_auth_service.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';

/// 토큰 정보를 그대로 출력 (디버그 모드에서만)
void _printTokenRaw(String token, String tokenName) {
  if (!kDebugMode) return;
  debugPrint('🔑 $tokenName: $token (총 ${token.length}자)');
}

/// 토큰 정보 출력 함수 (디버그 모드에서만)
Future<void> printTokens() async {
  if (!kDebugMode) return;
  
  debugPrint('=== 토큰 정보 ===');
  
  // 백엔드 액세스 토큰
  final backendToken = await TokenService.getAccessToken();
  if (backendToken != null) {
    _printTokenRaw(backendToken, '백엔드 액세스 토큰');
  } else {
    debugPrint('❌ 백엔드 액세스 토큰: 없음');
  }
  
  // 카카오 액세스 토큰 (SDK에서 직접)
  try {
    final kakaoToken = await TokenManagerProvider.instance.manager.getToken();
    if (kakaoToken?.accessToken != null) {
      _printTokenRaw(kakaoToken!.accessToken, '카카오 액세스 토큰');
    } else {
      debugPrint('❌ 카카오 액세스 토큰: 없음');
    }
  } catch (e) {
    debugPrint('❌ 카카오 액세스 토큰 조회 실패: $e');
  }
  
  // 저장된 카카오 토큰
  final storedKakaoToken = await TokenService.getKakaoAccessToken();
  if (storedKakaoToken != null) {
    _printTokenRaw(storedKakaoToken, '저장된 카카오 토큰');
  } else {
    debugPrint('❌ 저장된 카카오 토큰: 없음');
  }
  
  debugPrint('================');
}

/// 토큰 자동 갱신 시도
Future<void> _attemptTokenRefresh() async {
  if (!kDebugMode) return;
  debugPrint('=== 토큰 자동 갱신 시도 ===');
  
  try {
    // Google 로그인 상태 확인
    final googleSignedIn = await GoogleAuthService.isSignedIn();
    if (googleSignedIn) {
      debugPrint('💡 Google 로그인 사용 중');
      try {
        // Google 사용자 정보 및 토큰 조회
        final googleUser = await GoogleAuthService.getCurrentUser();
        if (googleUser != null) {
          final googleIdToken = googleUser['idToken'];
          final googleAccessToken = googleUser['accessToken'];
          
          debugPrint('═══════════════════════════════════════════════════════════');
          debugPrint('📝 토큰 정보 (앱 시작 시):');
          if (googleIdToken != null && googleIdToken.toString().isNotEmpty) {
            final idTokenStr = googleIdToken.toString();
            // 토큰 만료 시간 확인
            try {
              final parts = idTokenStr.split('.');
              if (parts.length == 3) {
                final payload = parts[1];
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
                    debugPrint('⚠️ Google ID Token 만료됨 (${timeLeft.inMinutes.abs()}분 전 만료)');
                    debugPrint('   만료 시간: ${expDate.toIso8601String()}');
                    debugPrint('   현재 시간: ${now.toIso8601String()}');
                  } else {
                    debugPrint('✅ Google ID Token 유효함 (${timeLeft.inMinutes}분 ${timeLeft.inSeconds % 60}초 남음)');
                    debugPrint('   만료 시간: ${expDate.toIso8601String()}');
                  }
                }
              }
            } catch (e) {
              debugPrint('⚠️ 토큰 만료 시간 확인 실패: $e');
            }
            
            // 토큰을 마스킹하여 출력 (디버그 모드에서만)
            _printTokenRaw(idTokenStr, 'Google ID Token');
          } else {
            debugPrint('⚠️ Google ID Token이 없습니다');
          }
          debugPrint('═══════════════════════════════════════════════════════════');
        }
      } catch (e) {
        debugPrint('❌ Google 토큰 조회 실패: $e');
      }
      debugPrint('======================');
      return;
    }
    
    // 카카오 로그인인 경우에만 카카오 SDK에서 토큰 확인 및 필요시 자동 갱신
    final hasToken = await AuthApi.instance.hasToken();
    if (hasToken) {
      debugPrint('카카오 토큰 존재 - 상태 확인 중');
      try {
        // 먼저 토큰 만료 시간 확인 (갱신하지 않고)
        final tokenInfo = await KakaoAuthService.getTokenInfo();
        if (tokenInfo != null) {
          final expiresIn = tokenInfo['expiresIn'] as int;
          final expiresAt = tokenInfo['expiresAt'] as String;
          final isExpired = tokenInfo['isExpired'] as bool;
          final now = DateTime.now();
          final expiryDate = DateTime.parse(expiresAt);
          final timeLeft = expiryDate.difference(now);
          
          // 토큰이 만료되었거나 5분 이내로 만료 예정인 경우에만 갱신
          final shouldRefresh = isExpired || timeLeft.inMinutes < 5;
          
          if (isExpired) {
            debugPrint('⚠️ 카카오 액세스 토큰 만료됨 (${timeLeft.inMinutes.abs()}분 전 만료) - 갱신 시도');
          } else if (shouldRefresh) {
            debugPrint('⚠️ 카카오 액세스 토큰 곧 만료됨 (${timeLeft.inMinutes}분 남음) - 갱신 시도');
          } else {
            debugPrint('✅ 카카오 액세스 토큰 유효함 (${timeLeft.inMinutes}분 ${timeLeft.inSeconds % 60}초 남음) - 갱신 불필요');
            debugPrint('   유효 기간: ${expiresIn}초 (${(expiresIn / 3600).toStringAsFixed(1)}시간)');
            debugPrint('   만료 시간: $expiresAt');
          }
          
          // 토큰이 만료되었거나 곧 만료될 때만 갱신
          if (shouldRefresh) {
            debugPrint('토큰 갱신 중...');
            // UserApi.instance.me() 호출로 토큰 자동 갱신
            final user = await UserApi.instance.me();
            debugPrint('✅ 카카오 토큰 갱신 성공: userId=${user.id}');
            
            // 갱신된 토큰 정보 다시 확인
            final refreshedTokenInfo = await KakaoAuthService.getTokenInfo();
            if (refreshedTokenInfo != null) {
              final refreshedExpiresIn = refreshedTokenInfo['expiresIn'] as int;
              final refreshedExpiresAt = refreshedTokenInfo['expiresAt'] as String;
              final refreshedTimeLeft = DateTime.parse(refreshedExpiresAt).difference(now);
              debugPrint('   갱신 후 유효 기간: ${refreshedExpiresIn}초 (${(refreshedExpiresIn / 3600).toStringAsFixed(1)}시간)');
              debugPrint('   갱신 후 만료 시간: $refreshedExpiresAt');
              debugPrint('   갱신 후 남은 시간: ${refreshedTimeLeft.inMinutes}분');
            }
          }
          
          // 갱신 여부와 관계없이 현재 토큰 출력 (디버그 모드에서만, 마스킹)
          if (kDebugMode) {
            final token = await TokenManagerProvider.instance.manager.getToken();
            if (token?.accessToken != null) {
              _printTokenRaw(token!.accessToken, '카카오 액세스 토큰');
              if (token?.refreshToken != null) {
                _printTokenRaw(token!.refreshToken!, '카카오 리프레시 토큰');
              }
            }
          }
        } else {
          debugPrint('⚠️ 토큰 정보 조회 실패');
        }
      } catch (e) {
        debugPrint('❌ 카카오 토큰 확인 실패: $e');
      }
    } else {
      // 카카오 토큰이 없고 Google도 로그인 안 된 경우만 메시지 출력
      if (!googleSignedIn) {
        debugPrint('❌ 카카오 토큰 없음 - 로그인 필요');
      }
    }
  } catch (e) {
    debugPrint('❌ 토큰 갱신 시도 중 오류: $e');
  }
  
  debugPrint('======================');
}

/// 카카오 토큰 디버깅 함수 - 터미널에서 호출 가능 (디버그 모드에서만)
/// 사용법: main.dart에서 debugKakaoToken() 주석을 해제하고 Hot Reload
Future<void> debugKakaoToken() async {
  if (!kDebugMode) return;
  debugPrint('=== 카카오 토큰 디버깅 ===');
  
  try {
    // 1. 토큰 존재 여부 확인
    final hasToken = await AuthApi.instance.hasToken();
    debugPrint('토큰 존재 여부: $hasToken');
    
    if (!hasToken) {
      debugPrint('❌ 카카오 토큰이 없습니다. 로그인이 필요합니다.');
      return;
    }
    
    // 2. 사용자 정보 조회 (토큰 자동 갱신 포함)
    try {
      final user = await UserApi.instance.me();
      debugPrint('✅ 사용자 정보 조회 성공: userId=${user.id}');
      
      // 3. 토큰 정보 가져오기
      final token = await TokenManagerProvider.instance.manager.getToken();
      
      if (token != null) {
        _printTokenRaw(token.accessToken, '액세스 토큰');
        if (token.refreshToken != null) {
          _printTokenRaw(token.refreshToken!, '리프레시 토큰');
        }
        
        // 4. 백엔드 토큰도 확인
        final backendToken = await TokenService.getAccessToken();
        if (backendToken != null) {
          _printTokenRaw(backendToken, '백엔드 토큰');
        } else {
          debugPrint('❌ 백엔드 토큰이 없습니다');
        }
        
      } else {
        debugPrint('❌ 토큰 정보를 가져올 수 없습니다');
      }
      
    } catch (e) {
      debugPrint('❌ 사용자 정보 조회 실패: $e');
    }
    
  } catch (e) {
    debugPrint('❌ 토큰 디버깅 중 오류: $e');
  }
  
  debugPrint('======================');
}

/// Alpaca 상태 확인 함수
Future<void> checkAlpacaStatus() async {
  debugPrint('=== Alpaca 상태 확인 ===');
  
  try {
    final status = await AuthService.getAlpacaStatus();
    if (status != null) {
      debugPrint('✅ Alpaca 상태 조회 성공');
      debugPrint('연결 상태: ${status['success']}');
      debugPrint('상세 정보: ${status['alpacaStatus']}');
      
      if (status['tokenExpired'] == true) {
        debugPrint('⚠️ Alpaca 토큰이 만료되었습니다. 갱신을 시도합니다...');
        final refreshResult = await AuthService.refreshAlpacaToken();
        debugPrint('토큰 갱신 결과: $refreshResult');
      }
    } else {
      debugPrint('❌ Alpaca 상태 조회 실패');
    }
  } catch (e) {
    debugPrint('❌ Alpaca 상태 확인 중 오류: $e');
  }
  
  debugPrint('====================');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 초기화
  await EnvConfig.initialize();
  
  // 오래된 토큰 확인 및 삭제 (앱 시작 시)
  await ApiClient.checkAndClearOldTokens();
  
  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
  
  // 토큰 자동 갱신 시도
  await _attemptTokenRefresh();
  
  // 백엔드 토큰이 있으면 WebSocket 연결 시도
  final backendToken = await TokenService.getAccessToken();
  if (backendToken != null) {
    if (kDebugMode) {
      debugPrint('백엔드 토큰 감지 - WebSocket 연결 시도');
      _printTokenRaw(backendToken, '백엔드 액세스 토큰');
    }
    try {
      await OrderWebSocketService.instance.connect();
      if (kDebugMode) {
        debugPrint('✅ 앱 시작 시 WebSocket 연결 성공');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 앱 시작 시 WebSocket 연결 실패 (무시): $e');
      }
    }
  } else {
    if (kDebugMode) {
      debugPrint('백엔드 토큰 없음 - WebSocket 연결 건너뜀');
    }
  }
  
  // 개발용: 강제 로그아웃 (필요시 주석 해제)
  // await AuthService.logout();
  // debugPrint('강제 로그아웃 완료');
  
  // 커맨드 실행 플래그 처리: flutter run --dart-define=RUN_COMMAND=getKakaoToken
  const runCommand = String.fromEnvironment('RUN_COMMAND');
  if (runCommand.isNotEmpty) {
    switch (runCommand) {
      case 'getKakaoToken':
        await debugKakaoToken();
        break;
      case 'printTokens':
        await printTokens();
        break;
      default:
        debugPrint('알 수 없는 RUN_COMMAND: $runCommand');
    }
  }
  
  // 디버깅: 토큰 정보 출력 (개발 중에만 사용)
  // debugKakaoToken(); // 이 줄의 주석을 해제하면 토큰 정보가 출력됩니다
  
  // 에러 처리 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Dart Error: $error');
    return true;
  };
  
  runQbitApp();
}