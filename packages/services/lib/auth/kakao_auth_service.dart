import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qbit_core/config/app_config.dart';
import 'package:flutter/material.dart';

final logger = Logger();

class KakaoAuthService {
  static final Dio _dio = Dio();

  /// 카카오 로그인 실행
  static Future<bool> login() async {
    try {
      // 백엔드 OAuth2 엔드포인트로 전체 페이지 이동
      final authUrl = '${AppConfig.baseUrl}/oauth2/authorization/kakao';
      
      logger.i('카카오 로그인 시작: $authUrl');

      if (kIsWeb) {
        // 웹에서는 window.location.href 방식 사용
        // TODO: 추후 변경 필요(문제없다면 모바일이랑 통일해도 될듯)
        try {
          // Flutter 웹에서 JavaScript 실행
          await launchUrl(
            Uri.parse(authUrl), 
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          logger.e('웹 리다이렉트 실패: $e');
          return false;
        }
      } else {
        // 모바일에서는 기본 모드
        if (await canLaunchUrl(Uri.parse(authUrl))) {
          await launchUrl(
            Uri.parse(authUrl), 
            mode: LaunchMode.platformDefault,
          );
        } else {
          logger.e('$authUrl 를 열 수 없습니다.');
          return false;
        }
      }
      
      logger.i('백엔드 OAuth2 엔드포인트로 리다이렉트 완료');
      return true;
    } catch (e, stack) {
      logger.e("로그인 중 예외 발생: $e\n$stack");
      return false;
    }
  }

  /// 인가 코드로 액세스 토큰 요청 (REST API)
  static Future<Map<String, dynamic>?> requestAccessToken(String code) async {
    try {
      final response = await _dio.post(
        'https://kauth.kakao.com/oauth/token',
        data: {
          'grant_type': 'authorization_code',
          'client_id': AppConfig.kakaoRestApiKey,
          'redirect_uri': AppConfig.kakaoRedirectUri,
          'code': code,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('액세스 토큰 요청 성공');
        return response.data;
      }
    } catch (e) {
      logger.e('액세스 토큰 요청 실패: $e');
    }
    return null;
  }

  /// 액세스 토큰으로 사용자 정보 조회 (REST API)
  static Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    try {
      final response = await _dio.get(
        'https://kapi.kakao.com/v2/user/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('사용자 정보 조회 성공');
        return response.data;
      }
    } catch (e) {
      logger.e('사용자 정보 조회 실패: $e');
    }
    return null;
  }

  /// 액세스 토큰 정보 조회 (REST API)
  static Future<Map<String, dynamic>?> getTokenInfo(String accessToken) async {
    try {
      final response = await _dio.get(
        'https://kapi.kakao.com/v1/user/access_token_info',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('토큰 정보 조회 성공');
        return response.data;
      }
    } catch (e) {
      logger.e('토큰 정보 조회 실패: $e');
    }
    return null;
  }

  /// 로그아웃 (REST API)
  static Future<bool> logout(String accessToken) async {
    try {
      final response = await _dio.post(
        'https://kapi.kakao.com/v1/user/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('카카오 로그아웃 성공');
        return true;
      }
    } catch (e) {
      logger.e('카카오 로그아웃 실패: $e');
    }
    return false;
  }

  /// 연결 해제 (REST API)
  static Future<bool> unlink(String accessToken) async {
    try {
      final response = await _dio.post(
        'https://kapi.kakao.com/v1/user/unlink',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        logger.i('카카오 연결 해제 성공');
        return true;
      }
    } catch (e) {
      logger.e('카카오 연결 해제 실패: $e');
    }
    return false;
  }
}
