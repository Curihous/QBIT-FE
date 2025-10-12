import 'package:logger/logger.dart';
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
            // 3. 토큰 저장
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
      if (await TokenService.isLoggedIn()) {
        // TODO: 백엔드 API로 사용자 정보 조회 구현
        return await KakaoAuthService.getSimpleUserInfo();
      } else {
        // 카카오 SDK로만 사용자 정보 조회
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
      // 백엔드 토큰과 카카오 토큰 모두 확인
      final backendLoggedIn = await TokenService.isLoggedIn();
      final kakaoLoggedIn = await KakaoAuthService.hasToken();
      
      return backendLoggedIn && kakaoLoggedIn;
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
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        logger.e('리프레시 토큰이 없습니다');
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
          
          logger.i('토큰 갱신 성공');
          return true;
        } else {
          logger.e('토큰 갱신 실패: ${response.message}');
          return false;
        }
      } else {
        logger.e('토큰 갱신 API 호출 실패');
        return false;
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
}