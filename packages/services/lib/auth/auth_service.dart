import 'package:logger/logger.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/google_auth_service.dart';
import 'package:qbit_services/auth/alpaca_auth_service.dart';
import 'package:qbit_services/api/auth_api_service.dart';
import 'package:qbit_services/models/auth_models.dart';
import 'package:qbit_services/storage/token_service.dart';

final logger = Logger();

class AuthService {
  /// 구글 로그인 (백엔드 연동)
  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    try {
      logger.i('구글 로그인 시작');
      
      // 1. 구글 SDK로 로그인
      final googleResult = await GoogleAuthService.login();
      if (googleResult == null || !googleResult['success']) {
        logger.e('구글 로그인 실패');
        return {'success': false, 'error': '구글 로그인 실패'};
      }

      final googleIdToken = googleResult['idToken'];
      final googleAccessToken = googleResult['accessToken'];
      final userId = googleResult['userId'];
      final email = googleResult['email'];
      final displayName = googleResult['displayName'];

      logger.i('구글 로그인 결과: idToken=${googleIdToken != null ? "있음" : "없음"}, accessToken=${googleAccessToken != null ? "있음" : "없음"}');
      
      // ID 토큰이 없으면 에러
      if (googleIdToken == null || googleIdToken.isEmpty) {
        logger.e('구글 ID 토큰이 없습니다. Google Cloud Console 설정을 확인하세요.');
        return {
          'success': false, 
          'error': '구글 ID 토큰을 받지 못했습니다. Google Cloud Console OAuth 설정을 확인하세요.'
        };
      }

      // 2. 백엔드 API로 로그인
      final backendResult = await AuthApiService.googleLogin(
        googleIdToken: googleIdToken,
      );

      if (backendResult == null) {
        logger.e('백엔드 구글 로그인 API 호출 실패');
        return {'success': false, 'error': '백엔드 로그인 실패'};
      }

      final response = GoogleLoginResponse.fromJson(backendResult);
      
      if (response.accessToken == null) {
        logger.e('백엔드 구글 로그인 실패: 액세스 토큰 없음');
        return {'success': false, 'error': '백엔드 로그인 실패: 액세스 토큰 없음'};
      }

      // 3. 토큰 저장
      await TokenService.saveAccessToken(response.accessToken!);

      logger.i('구글 로그인 성공');
      return {
        'success': true,
        'userId': response.userId?.toString() ?? userId,
        'email': response.email ?? email,
        'displayName': response.nickname ?? displayName,
        'accessToken': response.accessToken,
        'isNewUser': response.isNewUser,
        'expiresIn': response.expiresIn,
      };
    } catch (error) {
      logger.e('구글 로그인 중 예외 발생: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

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
      
      // 2. 백엔드 API로 로그인
      final backendResult = await AuthApiService.kakaoLogin(
        kakaoAccessToken: kakaoAccessToken,
        userId: userId,
        nickname: nickname,
        email: email,
      );

      if (backendResult == null) {
        logger.e('백엔드 카카오 로그인 API 호출 실패');
        return {'success': false, 'error': '백엔드 로그인 실패'};
      }

      final response = KakaoLoginResponse.fromJson(backendResult);
      
      if (response.accessToken == null) {
        logger.e('백엔드 카카오 로그인 실패: 액세스 토큰 없음');
        return {'success': false, 'error': '백엔드 로그인 실패: 액세스 토큰 없음'};
      }

      // 3. 토큰 저장
      await TokenService.saveAccessToken(response.accessToken!);
      await TokenService.saveKakaoAccessToken(kakaoAccessToken);
      await TokenService.saveKakaoUserId(userId);

      logger.i('카카오 로그인 성공');
      return {
        'success': true,
        'userId': response.userId?.toString() ?? userId,
        'nickname': response.nickname ?? nickname,
        'email': response.email ?? email,
        'accessToken': response.accessToken,
        'isNewUser': response.isNewUser,
        'expiresIn': response.expiresIn,
      };
    } catch (error) {
      logger.e('로그인 중 예외 발생: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// 현재 사용자 정보 조회
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // 백엔드에서 사용자 정보 조회
      if (await TokenService.hasBackendToken()) {
        final userInfo = await AuthApiService.getCurrentUser();
        if (userInfo != null) {
          logger.i('백엔드에서 사용자 정보 조회 성공');
          return userInfo;
        }
      }
      
      // 백엔드 실패 시 소셜 로그인(카카오/구글)에서 조회
      if (await KakaoAuthService.hasToken()) {
        logger.i('카카오 SDK에서 사용자 정보 조회');
        return await KakaoAuthService.getSimpleUserInfo();
      } else if (await GoogleAuthService.isSignedIn()) {
        logger.i('구글 SDK에서 사용자 정보 조회');
        return await GoogleAuthService.getSimpleUserInfo();
      }
      
      logger.e('사용자 정보를 조회할 수 없습니다');
      return null;
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

      // 2. 소셜 로그인 SDK 로그아웃
      await Future.wait([
        KakaoAuthService.logout().catchError((e) {
          logger.w('카카오 로그아웃 실패 (무시): $e');
          return false;
        }),
        GoogleAuthService.logout().catchError((e) {
          logger.w('구글 로그아웃 실패 (무시): $e');
          return false;
        }),
      ]);

      // 3. 로컬 토큰 삭제
      await TokenService.clearAllTokens();

      logger.i('로그아웃 완료');
      return true;
    } catch (error) {
      logger.e('로그아웃 실패: $error');
      return false;
    }
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    try {
      // 소셜 로그인 또는 백엔드 토큰 중 하나라도 있으면 로그인 상태
      final results = await Future.wait([
        KakaoAuthService.hasToken(),
        GoogleAuthService.isSignedIn(),
        TokenService.hasBackendToken(),
      ]);
      
      return results.any((hasToken) => hasToken);
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
      
      // 1. 로그인 타입 확인
      final kakaoLoggedIn = await KakaoAuthService.hasToken();
      final googleLoggedIn = await GoogleAuthService.isSignedIn();
      
      // 2. 소셜 로그인(카카오/구글) 토큰 갱신
      if (kakaoLoggedIn) {
        final result = await KakaoAuthService.checkOrValidateAccessToken();
        if (result?['success'] != true) {
          logger.e('카카오 토큰 갱신 실패. 재로그인 필요.');
          return false;
        }
        logger.i('카카오 토큰 유효함');
      } else if (googleLoggedIn) {
        final result = await GoogleAuthService.refreshToken();
        if (result?['success'] != true) {
          logger.e('구글 토큰 갱신 실패. 재로그인 필요.');
          return false;
        }
        logger.i('구글 토큰 갱신 성공');
      } else {
        logger.e('로그인된 소셜 계정이 없습니다');
        return false;
      }
      
      // 3. 백엔드 JWT 토큰 갱신
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        logger.i('백엔드 리프레시 토큰 없음. 소셜 로그인만 사용.');
        return true; // 소셜 로그인만으로도 OK
      }

      final result = await AuthApiService.refreshToken(refreshToken: refreshToken);
      if (result != null) {
        final response = RefreshTokenResponse.fromJson(result);
        
        if (response.success && response.accessToken != null) {
          await TokenService.saveAccessToken(response.accessToken!);
          if (response.refreshToken != null) {
            await TokenService.saveRefreshToken(response.refreshToken!);
          }
          logger.i('백엔드 JWT 토큰 갱신 성공');
          return true;
        }
      }
      
      // 백엔드 토큰 갱신 실패 - 재로그인 필요
      logger.e('백엔드 JWT 토큰 갱신 실패. 재로그인 필요.');
      return false;
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

  /// 테스트 로그인 (.env 파일의 JWT 토큰 사용)
  static Future<Map<String, dynamic>> loginWithTestToken() async {
    try {
      logger.i('테스트 로그인 시작');
      
      final backendToken = EnvConfig.backendTestAccessToken;
      
      if (backendToken.isEmpty) {
        logger.e('.env에 BACKEND_TEST_ACCESS_TOKEN 없음');
        return {
          'success': false, 
          'error': '.env 파일에 BACKEND_TEST_ACCESS_TOKEN을 설정해주세요'
        };
      }
      
      // 토큰 저장
      await TokenService.saveAccessToken(backendToken);
      
      logger.i('테스트 로그인 성공');
      return {'success': true};
    } catch (error) {
      logger.e('테스트 로그인 실패: $error');
      return {'success': false, 'error': '테스트 로그인 실패'};
    }
  }
}