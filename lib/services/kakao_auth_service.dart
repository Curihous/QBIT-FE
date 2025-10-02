import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class KakaoAuthService {
  static final Dio _dio = Dio();

  /// 카카오 로그인 초기화
  static Future<void> initialize() async {
    kakao.UserApi.instance;
  }

  /// 카카오 로그인 실행
  static Future<bool> login() async {
    try {
      // 카카오톡으로 로그인 시도
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      
      if (isInstalled) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 로그인 성공 시 사용자 정보 가져오기
      kakao.User user = await kakao.UserApi.instance.me();
      print('로그인된 카카오 사용자: ${user.kakaoAccount?.email}');
      
      return true;
    } catch (error) {
      print('카카오 로그인 실패: $error');
      return false;
    }
  }

  /// 백엔드 서버에 JWT 토큰 요청
  static Future<Map<String, dynamic>?> requestJwtToken(String kakaoAccessToken) async {
    try {
      final response = await _dio.post(
        '${AppConfig.backendUrl}/auth/signin/kakao',
        data: {
          'accessToken': kakaoAccessToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (error) {
      print('백엔드 JWT 토큰 요청 실패: $error');
    }
    return null;
  }

  /// 🔄 Access Token을 Refresh Token으로 갱신
  static Future<Map<String, dynamic>?> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '${AppConfig.backendUrl}/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (error) {
      print('토큰 갱신 실패: $error');
    }
    return null;
  }

  /// 로그아웃
  static Future<void> logout() async {
    try {
      await kakao.UserApi.instance.logout();
      print('카카오 로그아웃 성공');
    } catch (error) {
      print('카카오 로그아웃 실패: $error');
    }
  }
}
