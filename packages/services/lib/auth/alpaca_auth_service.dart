import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../api/auth_api_service.dart';
import 'kakao_auth_service.dart';

final logger = Logger();

class AlpacaAuthService {
  /// Alpaca OAuth 인증 시작
  static Future<Map<String, dynamic>?> startAlpacaAuth() async {
    try {
      // 1. 백엔드에서 인증 URL 가져오기
      final authorizeUrl = await AuthApiService.getAlpacaAuthorizeUrl();
      if (authorizeUrl == null) {
        return {'success': false, 'error': '인증 URL을 가져올 수 없습니다'};
      }
      
      // 2. url_launcher로 브라우저 열기
      final uri = Uri.parse(authorizeUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return {'success': false, 'error': '브라우저를 열 수 없습니다'};
      }
      
      // 3. 사용자가 브라우저에서 인증 완료 (백엔드로 자동 콜백)
      logger.i('Alpaca 인증 URL 열림, 사용자 인증 대기 중...');
      
      // 브라우저에서 인증이 완료되면 백엔드가 자동으로 처리
      // 앱으로 돌아온 후 상태 확인
      await Future.delayed(const Duration(seconds: 2));
      
      // 4. 상태 확인
      // 실제 Alpaca 연결 상태 확인 (개발/프로덕션 모두)
      final statusResult = await _checkAlpacaStatus();
      if (statusResult != null && statusResult['success'] == true) {
        return {'success': true, 'message': 'Alpaca 연동이 완료되었습니다!'};
      } else {
        final errorMessage = statusResult?['error'] ?? 'Alpaca 연동 상태를 확인할 수 없습니다';
        return {'success': false, 'error': errorMessage};
      }
    } catch (error) {
      logger.e('Alpaca 인증 시작 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 연결 상태 확인
  static Future<Map<String, dynamic>?> _checkAlpacaStatus() async {
    try {
      logger.i('Alpaca 연결 상태 확인');
      
      // 카카오 토큰 정보도 함께 확인
      final kakaoTokenInfo = await KakaoAuthService.getTokenInfo();
      
      final status = await AuthApiService.getAlpacaStatus();
      
      if (status != null) {
        // 실제 연동 상태 확인 
        final connectionStatus = status['connectionStatus'];
        final connected = status['connected'] == true;
        final tokenExpired = status['tokenExpired'] == true;
        final isConnected = connected; // connected 필드만 확인
        
        // 상태 요약 (릴리스에서도 출력)
        logger.i('=== 알파카 상태 요약 ===');
        logger.i('연결 상태: $connectionStatus (connected: $connected)');
        logger.i('토큰 만료: $tokenExpired');
        logger.i('카카오 토큰: ${kakaoTokenInfo?['isExpired'] == false ? '유효' : '만료'}');
        logger.i('백엔드 응답 키: ${status.keys.toList()}');
        logger.i('연결 상태만 확인하여 사용 가능');
        
        // 디버그 모드에서만 상세 정보 출력
        if (kDebugMode) {
          logger.i('=== 토큰 시간 정보 상세 (디버그 모드) ===');
          final now = DateTime.now();
          logger.i('현재 시간: ${now.toIso8601String()}');
          logger.i('현재 시간 (UTC): ${now.toUtc().toIso8601String()}');
          
          // 카카오 토큰 만료 시간 상세
          if (kakaoTokenInfo?['expiresAt'] != null) {
            logger.i('카카오 토큰 만료 시간: ${kakaoTokenInfo!['expiresAt']}');
          }
          
          // 백엔드 응답에서 토큰 관련 시간 정보 찾기
          status.forEach((key, value) {
            if (key.toLowerCase().contains('time') || 
                key.toLowerCase().contains('date') || 
                key.toLowerCase().contains('expire') ||
                key.toLowerCase().contains('created') ||
                key.toLowerCase().contains('updated')) {
              logger.i('$key: $value');
            }
          });
          
          // 알파카 관련 키들도 확인
          status.forEach((key, value) {
            if (key.toLowerCase().contains('alpaca')) {
              logger.i('$key: $value');
            }
          });
          
          logger.i('========================');
        } else {
          // 릴리스 모드에서는 민감한 정보 마스킹
          logger.i('토큰 정보: **** (민감정보 마스킹)');
          logger.i('상세 정보는 디버그 모드에서만 출력됩니다');
          logger.i('========================');
        }
        
        // 토큰이 만료되었다고 판단되면 경고만 표시 
        if (tokenExpired) {
          logger.i('토큰 만료 감지');
          logger.i('연결 상태는 정상이므로 사용 가능');
        }
        
        return {
          'success': isConnected,
          'alpacaStatus': status,
          'accountId': status['accountId'] ?? status['alpacaAccountId'] ?? 'Unknown',
          'tokenExpired': tokenExpired,
        };
      } else {
        logger.e('Alpaca 연결 상태 확인 실패');
        return {'success': false, 'error': '연결 상태를 확인할 수 없습니다'};
      }
    } catch (error) {
      logger.e('Alpaca 연결 상태 확인 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 연결 상태 조회 (공개 메서드)
  static Future<Map<String, dynamic>?> getAlpacaStatus() async {
    return await _checkAlpacaStatus();
  }

  /// Alpaca 토큰 갱신
  static Future<Map<String, dynamic>?> refreshAlpacaToken() async {
    try {
      logger.i('Alpaca 토큰 갱신 시작');
      
      final success = await AuthApiService.refreshAlpacaToken();
      if (success) {
        logger.i('Alpaca 토큰 갱신 성공');
        
        // 갱신 후 상태 확인
        final statusResult = await _checkAlpacaStatus();
        return statusResult;
      } else {
        logger.e('Alpaca 토큰 갱신 실패');
        return {'success': false, 'error': '토큰 갱신에 실패했습니다'};
      }
    } catch (error) {
      logger.e('Alpaca 토큰 갱신 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Alpaca 연결 해제
  static Future<bool> disconnectAlpaca() async {
    try {
      logger.i('Alpaca 연결 해제 시작');
      
      final success = await AuthApiService.disconnectAlpaca();
      if (success) {
        logger.i('Alpaca 연결 해제 성공');
        return true;
      } else {
        logger.e('Alpaca 연결 해제 실패');
        return false;
      }
    } catch (error) {
      logger.e('Alpaca 연결 해제 실패: $error');
      return false;
    }
  }

  /// 리소스 정리
  static Future<void> dispose() async {
    // 현재는 특별한 정리 작업이 없음
  }
}