import 'package:dio/dio.dart';
import 'package:qbit_core/models/user.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';
import 'base_api_service.dart';

/// 인증 관련 API 서비스
class AuthApiService extends BaseApiService {
  /// 카카오 인가 코드를 백엔드로 전송
  Future<Map<String, dynamic>> sendKakaoCodeToBackend(String code) async {
    final response = await post(
      '/login/oauth2/code/kakao',
      data: {'code': code},
    );
    
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    
    throw ApiException(
      message: '카카오 로그인 실패',
      statusCode: response.statusCode,
      endpoint: '/login/oauth2/code/kakao',
    );
  }

  /// 카카오 사용자 정보를 백엔드로 전송 (REST API 방식)
  Future<Map<String, dynamic>> sendKakaoUserInfoToBackend(
    String kakaoAccessToken, 
    Map<String, dynamic> kakaoUserInfo,
  ) async {
    final response = await post(
      '/auth/kakao',
      data: {
        'kakaoAccessToken': kakaoAccessToken,
        'kakaoUserInfo': kakaoUserInfo,
      },
    );
    
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    
    throw ApiException(
      message: '카카오 사용자 정보 전송 실패',
      statusCode: response.statusCode,
      endpoint: '/auth/kakao',
    );
  }

  /// 토큰 갱신 API 호출
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    final response = await post(
      '/auth/refresh-tokens',
      data: {'refreshToken': refreshToken},
    );
    
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    
    throw ApiException(
      message: '토큰 갱신 실패',
      statusCode: response.statusCode,
      endpoint: '/auth/refresh-tokens',
    );
  }

  /// 로그아웃 API 호출
  Future<void> logout() async {
    final response = await post('/auth/logout');
    
    if (response.statusCode != 200) {
      throw ApiException(
        message: '로그아웃 실패',
        statusCode: response.statusCode,
        endpoint: '/auth/logout',
      );
    }
  }
}

/// 사용자 관련 API 서비스
class UserApiService extends BaseApiService {
  /// 현재 사용자 정보 조회
  Future<User> getCurrentUser() async {
    final response = await get('/users/me');
    
    if (response.statusCode == 200) {
      return User.fromJson(response.data as Map<String, dynamic>);
    }
    
    throw ApiException(
      message: '사용자 정보 조회 실패',
      statusCode: response.statusCode,
      endpoint: '/users/me',
    );
  }

  /// 사용자 정보 업데이트
  Future<User> updateUser(Map<String, dynamic> userData) async {
    final response = await put(
      '/users/me',
      data: userData,
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(response.data as Map<String, dynamic>);
    }
    
    throw ApiException(
      message: '사용자 정보 업데이트 실패',
      statusCode: response.statusCode,
      endpoint: '/users/me',
    );
  }
}
