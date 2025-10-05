import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../api_service.dart';

final logger = Logger();

class KakaoAuthService {
  static final ApiService _apiService = ApiService();

  /// 카카오 로그인 실행 (Spring Security OAuth2 방식)
  static Future<bool> login() async {
    try {
      // 백엔드 Spring Security OAuth2 엔드포인트로 리다이렉트
      final redirectUrl = 'https://api.qbit.o-r.kr/oauth2/authorization/kakao';
      
      logger.i('🚀 카카오 로그인 시작: $redirectUrl');
      
      // 웹브라우저로 리다이렉트
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        logger.i('✅ 카카오 로그인 페이지로 리다이렉트 완료');
        
        // TODO: 백엔드에서 리다이렉트된 URL 처리 필요
        // 백엔드 OAuth2SuccessHandler가 다음 URL로 리다이렉트:
        // http://localhost:3000/oauth?accessToken=JWT토큰&userId=123&isNewUser=false
        
        return true;
      } else {
        logger.e('❌ 카카오 로그인 페이지 열기 실패');
        return false;
      }
    } catch (e, stack) {
      logger.e("⚠️ 로그인 중 예외 발생: $e\n$stack");
      return false;
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    try {
      // 백엔드 로그아웃 먼저 시도
      await _apiService.logout();
      
      // 카카오 로그아웃
      await UserApi.instance.logout();
      logger.i('✅ 로그아웃 성공');
    } catch (error) {
      logger.e('❌ 로그아웃 실패: $error');
    }
  }

  /// 연결 해제 (카카오계정과 앱 연결 해제)
  static Future<void> unlink() async {
    try {
      // 백엔드 연결 해제 먼저 시도
      await _apiService.logout();
      
      // 카카오 연결 해제
      await UserApi.instance.unlink();
      logger.i('✅ 연결 해제 성공');
    } catch (error) {
      logger.e('❌ 연결 해제 실패: $error');
    }
  }

  /// 현재 사용자 정보 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      if (await AuthApi.instance.hasToken()) {
        return await UserApi.instance.me();
      }
      return null;
    } catch (error) {
      logger.e('❌ 사용자 정보 조회 실패: $error');
      return null;
    }
  }

  /// 토큰 유효성 검증
  static Future<bool> isTokenValid() async {
    try {
      if (!await AuthApi.instance.hasToken()) {
        return false;
      }
      
      await UserApi.instance.accessTokenInfo();
      return true;
    } catch (error) {
      if (error is KakaoException && error.isInvalidTokenError()) {
        logger.w('⚠️ 토큰이 유효하지 않음');
        return false;
      }
      logger.e('❌ 토큰 유효성 검증 실패: $error');
      return false;
    }
  }
}