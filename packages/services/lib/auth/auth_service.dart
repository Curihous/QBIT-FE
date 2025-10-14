import 'package:logger/logger.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/alpaca_auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/models/auth_models.dart';
import 'package:qbit_services/storage/token_service.dart';

final logger = Logger();

class AuthService {
  /// 카카오 로그인 (백엔드 연동)
  static Future<Map<String, dynamic>?> login() async {
    try {
      logger.i('카카오 로그인 시작');
      
      // 환경변수로 개발/프로덕션 플로우 구분
      final useDevLogin = EnvConfig.useDevLogin;
      
      if (useDevLogin) {
        logger.i('개발 모드: .env 테스트 토큰으로 로그인');
        return await loginWithTestToken();
      }

      logger.i('프로덕션 모드: Kakao SDK 로그인');
      
      // 1. 카카오 SDK로 로그인
      final kakaoResult = await KakaoAuthService.login();
      if (kakaoResult == null || !kakaoResult['success']) {
        logger.e('카카오 로그인 실패');
        return {'success': false, 'error': '카카오 로그인 실패'};
      }

      final kakaoAccessToken = kakaoResult['accessToken'];
      final userId = kakaoResult['userId'];
      final nickname = kakaoResult['nickname'];
      final email = kakaoResult['email'];

      // 2. 카카오 토큰 상태 확인
      final tokenInfo = await KakaoAuthService.getTokenInfo();
      if (tokenInfo?['isExpired'] == true) {
        logger.e('❌ 카카오 토큰이 만료되었습니다. 재로그인이 필요합니다.');
        return {'success': false, 'error': '카카오 토큰이 만료되었습니다. 다시 로그인해주세요.'};
      }
      
      // 3. 백엔드 API로 로그인 (임시로 카카오만 사용)
      try {
        final backendResult = await AuthApiService.kakaoLogin(
          kakaoAccessToken: kakaoAccessToken,
          userId: userId,
          nickname: nickname,
          email: email,
        );

        if (backendResult != null) {
          final response = KakaoLoginResponse.fromJson(backendResult);
          
          if (response.accessToken != null) {
            // 토큰 저장
            await TokenService.saveAccessToken(response.accessToken!);
            await TokenService.saveKakaoAccessToken(kakaoAccessToken);
            await TokenService.saveKakaoUserId(userId);

            logger.i('백엔드 로그인 성공');
            return {
              'success': true,
              'userId': response.userId?.toString() ?? userId,
              'nickname': response.nickname ?? nickname,
              'email': response.email ?? email,
              'accessToken': response.accessToken,
              'refreshToken': null, // 백엔드에서 리프레시 토큰 미제공
              'isNewUser': response.isNewUser,
              'expiresIn': response.expiresIn,
            };
          } else {
            logger.e('백엔드 로그인 실패: 액세스 토큰 없음');
            return {'success': false, 'error': '백엔드 로그인 실패: 액세스 토큰 없음'};
          }
        } else {
          logger.e('백엔드 로그인 API 호출 실패');
          return {'success': false, 'error': '백엔드 로그인 API 호출 실패'};
        }
      } catch (backendError) {
        logger.w('백엔드 연결 실패, 카카오 로그인만 사용: $backendError');
        
        // 백엔드 연결 실패 시 카카오 로그인만 사용
        await TokenService.saveKakaoAccessToken(kakaoAccessToken);
        await TokenService.saveKakaoUserId(userId);

        return {
          'success': true,
          'userId': userId,
          'nickname': nickname,
          'email': email,
          'accessToken': kakaoAccessToken,
          'refreshToken': null,
          'backendConnected': false,
        };
      }
    } catch (error) {
      logger.e('로그인 중 예외 발생: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// 현재 사용자 정보 조회
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // 백엔드 토큰이 있으면 백엔드에서 사용자 정보 조회
      if (await TokenService.hasBackendToken()) {
        final backendUserInfo = await AuthApiService.getCurrentUser();
        if (backendUserInfo != null) {
          logger.i('백엔드에서 사용자 정보 조회 성공');
          return backendUserInfo;
        } else {
          logger.w('백엔드 사용자 정보 조회 실패, 카카오 SDK로 폴백');
          return await KakaoAuthService.getSimpleUserInfo();
        }
      } else {
        // 백엔드 토큰이 없으면 카카오 SDK로만 사용자 정보 조회
        logger.i('백엔드 토큰 없음, 카카오 SDK로 사용자 정보 조회');
      return await KakaoAuthService.getSimpleUserInfo();
      }
    } catch (error) {
      logger.e('사용자 정보 조회 실패: $error');
      return null;
    }
  }

  /// 로그아웃
  static Future<bool> logout() async {
    try {
      // 1. 백엔드 로그아웃 API 호출
      if (await TokenService.isLoggedIn()) {
        final backendLogout = await AuthApiService.logout();
        if (!backendLogout) {
          logger.w('백엔드 로그아웃 실패, 로컬 로그아웃 진행');
        }
      }

      // 2. 로컬 토큰 삭제
      await TokenService.clearAllTokens();

      // 3. 카카오 SDK 로그아웃
      await KakaoAuthService.logout();

      logger.i('로그아웃 성공');
      return true;
    } catch (error) {
      logger.e('로그아웃 실패: $error');
      return false;
    }
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      // 카카오 토큰이 있으면 로그인 상태로 간주 (백엔드 연결 실패 시에도 카카오 로그인만으로 사용 가능)
      final kakaoLoggedIn = await KakaoAuthService.hasToken();
      
      if (kakaoLoggedIn) {
        // 카카오 토큰이 있으면 로그인 상태
        return true;
      } else {
        // 카카오 토큰이 없으면 백엔드 토큰만으로도 확인
        return await TokenService.isLoggedIn();
      }
    } catch (e) {
      logger.e('로그인 상태 확인 실패: $e');
      return false;
    }
  }

  /// 액세스 토큰 정보 조회
  static Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      // 백엔드 토큰이 있으면 백엔드 토큰 정보 반환
      if (await TokenService.isLoggedIn()) {
        final accessToken = await TokenService.getAccessToken();
        final refreshToken = await TokenService.getRefreshToken();
        
        return {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'source': 'backend',
        };
      } else {
        // 카카오 SDK 토큰 정보 반환
      return await KakaoAuthService.getTokenInfo();
      }
    } catch (error) {
      logger.e('토큰 정보 조회 실패: $error');
      return null;
    }
  }

  /// 토큰 갱신
  static Future<bool> refreshAccessToken() async {
    try {
      logger.i('토큰 갱신 시작');
      
      // 1. 세션 타입 확인
      final isKakaoOnly = await TokenService.isKakaoOnlySession();
      final hasBackendToken = await TokenService.hasBackendToken();
      final hasRefreshToken = await TokenService.getRefreshToken() != null;
      
      // 2. 카카오 토큰 상태 확인 및 갱신
      final kakaoTokenInfo = await KakaoAuthService.getTokenInfo();
      if (kakaoTokenInfo?['isExpired'] == true) {
        logger.i('카카오 토큰 만료, 명시적 갱신 시도');
        
        // 카카오 토큰 갱신 시도
        final refreshResult = await KakaoAuthService.refreshAccessToken();
        if (refreshResult?['success'] == true && refreshResult?['refreshed'] == true) {
          // 갱신된 토큰 저장
          await TokenService.saveKakaoAccessToken(refreshResult!['accessToken']);
          await TokenService.saveKakaoUserId(refreshResult['userId']);
          logger.i('카카오 토큰 갱신 및 저장 완료');
        } else {
          logger.e('카카오 토큰 갱신 실패: ${refreshResult?['error']}');
          return false;
        }
      }
      
      // 3. 카카오 전용 세션 처리
      if (isKakaoOnly) {
        logger.i('카카오 전용 세션: 백엔드 토큰 갱신 불필요');
        return true; // 카카오 전용 세션에서는 백엔드 토큰 갱신 없이 성공 처리
      }
      
      // 4. 백엔드 토큰 재발급 시도
      final kakaoAccessToken = await TokenService.getKakaoAccessToken();
      if (kakaoAccessToken != null) {
        logger.i('카카오 토큰으로 백엔드 토큰 재발급 시도');
        
        final userId = await TokenService.getKakaoUserId();
        final result = await AuthApiService.kakaoLogin(
          kakaoAccessToken: kakaoAccessToken,
          userId: userId ?? '',
          nickname: '', // 필요시 저장된 값 사용
          email: '',
        );
        
        if (result != null) {
          final response = KakaoLoginResponse.fromJson(result);
          if (response.accessToken != null) {
            await TokenService.saveAccessToken(response.accessToken!);
            logger.i('카카오 토큰 기반 백엔드 토큰 재발급 성공');
            return true;
          }
        }
        
        logger.w('카카오 토큰 기반 백엔드 토큰 재발급 실패');
      }
      
      // 5. 백엔드 리프레시 토큰으로 폴백 (백엔드 토큰이 기대되는 경우만)
      if (hasBackendToken || hasRefreshToken) {
        final refreshToken = await TokenService.getRefreshToken();
        if (refreshToken == null) {
          logger.e('백엔드 토큰이 기대되지만 리프레시 토큰이 없습니다');
          return false;
        }

        final result = await AuthApiService.refreshToken(refreshToken: refreshToken);
        if (result != null) {
          final response = RefreshTokenResponse.fromJson(result);
          
          if (response.success) {
            // 새 토큰 저장
            if (response.accessToken != null) {
              await TokenService.saveAccessToken(response.accessToken!);
            }
            if (response.refreshToken != null) {
              await TokenService.saveRefreshToken(response.refreshToken!);
            }
            
            logger.i('백엔드 리프레시 토큰으로 토큰 갱신 성공');
            return true;
          } else {
            logger.e('백엔드 리프레시 토큰 갱신 실패: ${response.message}');
            return false;
          }
        } else {
          logger.e('백엔드 리프레시 토큰 갱신 API 호출 실패');
          return false;
        }
      } else {
        // 백엔드 토큰이 기대되지 않는 경우 (카카오 전용 세션)
        logger.i('백엔드 토큰이 기대되지 않음, 카카오 전용 세션으로 처리');
        return true;
      }
    } catch (error) {
      logger.e('토큰 갱신 중 예외 발생: $error');
      return false;
    }
  }

  /// Alpaca OAuth 인증 시작
  static Future<Map<String, dynamic>?> startAlpacaAuth() async {
    try {
      logger.i('Alpaca 인증 시작');
      return await AlpacaAuthService.startAlpacaAuth();
    } catch (error) {
      logger.e('Alpaca 인증 시작 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 연결 상태 확인
  static Future<Map<String, dynamic>?> getAlpacaStatus() async {
    try {
      logger.i('Alpaca 연결 상태 확인');
      return await AlpacaAuthService.getAlpacaStatus();
    } catch (error) {
      logger.e('Alpaca 연결 상태 확인 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 토큰 갱신
  static Future<Map<String, dynamic>?> refreshAlpacaToken() async {
    try {
      logger.i('Alpaca 토큰 갱신');
      return await AlpacaAuthService.refreshAlpacaToken();
    } catch (error) {
      logger.e('Alpaca 토큰 갱신 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 연결 해제
  static Future<bool> disconnectAlpaca() async {
    try {
      logger.i('Alpaca 연결 해제');
      return await AlpacaAuthService.disconnectAlpaca();
    } catch (error) {
      logger.e('Alpaca 연결 해제 실패: $error');
      return false;
    }
  }

  /// Alpaca 리스너 정리
  static Future<void> disposeAlpacaListener() async {
    try {
      await AlpacaAuthService.dispose();
      logger.i('Alpaca 리스너 정리 완료');
    } catch (error) {
      logger.e('Alpaca 리스너 정리 실패: $error');
    }
  }

  // .env 파일의 JWT 토큰으로 직접 로그인
  // TODO: 추후 제거
  static Future<Map<String, dynamic>> loginWithTestToken() async {
    try {
      logger.i('테스트 토큰으로 로그인 시작');
      
      final backendToken = EnvConfig.backendTestAccessToken;
      final kakaoToken = EnvConfig.kakaoTestAccessToken;
      
      if (backendToken.isEmpty) {
        logger.e('.env 파일에 BACKEND_TEST_ACCESS_TOKEN이 설정되지 않음');
        return {'success': false, 'error': '.env 파일에 BACKEND_TEST_ACCESS_TOKEN을 설정해주세요'};
      }
      
      // JWT 토큰 및 사용자 정보 저장
      await TokenService.saveAccessToken(backendToken);
      await TokenService.saveKakaoAccessToken(kakaoToken);
      await TokenService.saveKakaoUserId('1');
      
      logger.i('테스트 로그인 성공');
      return {'success': true};
    } catch (e, stack) {
      logger.e('테스트 로그인 중 예외 발생: $e\n$stack');
      return {'success': false, 'error': '로그인 중 오류가 발생했습니다'};
    }
  }
}