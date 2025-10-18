import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:qbit_core/config/env_config.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 3,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);

class GoogleAuthService {
  static GoogleSignIn? _googleSignInInstance;
  
  static GoogleSignIn get _googleSignIn {
    if (_googleSignInInstance != null) return _googleSignInInstance!;
    
    final webClientId = EnvConfig.googleWebClientId;
    
    _googleSignInInstance = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
      serverClientId: webClientId.isNotEmpty ? webClientId : null, // 웹 클라이언트 ID
    );
    
    return _googleSignInInstance!;
  }

  // 구글 로그인 실행
  static Future<Map<String, dynamic>?> login() async {
    try {
      logger.i('구글 로그인 시작');
      
      // 1. 자동 로그인 시도 (이전 세션 복원)
      GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
      
      if (currentUser != null) {
        logger.i('자동 로그인 성공: ${currentUser.email}');
      } else {
        // 2. 자동 로그인 실패 시 수동 로그인
        logger.i('자동 로그인 실패, 수동 로그인 시도');
        currentUser = await _googleSignIn.signIn();
      }
      
      if (currentUser == null) {
        logger.w('사용자가 구글 로그인을 취소했습니다');
        return {'success': false, 'error': '사용자 취소'};
      }

      logger.i('구글 로그인 성공: ${currentUser.email}');

      // 인증 정보 가져오기
      final GoogleSignInAuthentication auth = await currentUser.authentication;
      
      logger.i('구글 인증 토큰: idToken=${auth.idToken != null ? "있음(${auth.idToken?.substring(0, 20)}...)" : "없음"}, accessToken=${auth.accessToken != null ? "있음" : "❌없음"}');
      
      return {
        'success': true,
        'userId': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      };
    } catch (error) {
      logger.e('구글 로그인 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  // 로그아웃
  static Future<bool> logout() async {
    try {
      await _googleSignIn.signOut();
      logger.i('구글 로그아웃 성공');
      return true;
    } catch (error) {
      logger.e('구글 로그아웃 실패: $error');
      return false;
    }
  }

  // 연결 해제
  static Future<bool> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      logger.i('구글 연결 해제 성공');
      return true;
    } catch (error) {
      logger.e('구글 연결 해제 실패: $error');
      return false;
    }
  }

  // 현재 사용자 정보 조회
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // 1. 현재 사용자 확인
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      // 2. 없으면 자동 로그인 시도
      if (currentUser == null) {
        logger.i('현재 사용자 없음, 자동 로그인 시도');
        currentUser = await _googleSignIn.signInSilently();
      }
      
      if (currentUser == null) {
        logger.w('구글 사용자를 찾을 수 없습니다');
        return null;
      }

      // 3. 인증 정보 가져오기
      final GoogleSignInAuthentication auth = await currentUser.authentication;

      logger.i('구글 사용자 정보 조회 성공: ${currentUser.email}');
      
      return {
        'userId': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      };
    } catch (error) {
      logger.e('구글 사용자 정보 조회 실패: $error');
      return null;
    }
  }

  // 간단한 사용자 정보 조회 (기본 정보만)
  static Future<Map<String, dynamic>?> getSimpleUserInfo() async {
    try {
      // 1. 현재 사용자 확인
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      // 2. 없으면 자동 로그인 시도
      if (currentUser == null) {
        logger.i('현재 사용자 없음, 자동 로그인 시도');
        currentUser = await _googleSignIn.signInSilently();
      }
      
      if (currentUser == null) {
        logger.w('구글 사용자를 찾을 수 없습니다');
        return null;
      }

      logger.i('구글 간단한 사용자 정보 조회 성공: ${currentUser.email}');
      
      return {
        'userId': currentUser.id,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
      };
    } catch (error) {
      logger.e('구글 간단한 사용자 정보 조회 실패: $error');
      return null;
    }
  }

  // 로그인 상태 확인
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (error) {
      logger.e('구글 로그인 상태 확인 실패: $error');
      return false;
    }
  }

  // 토큰 갱신 (자동 로그인만 시도, 실패하면 로그인 화면으로)
  static Future<Map<String, dynamic>?> refreshToken() async {
    try {
      logger.i('구글 토큰 갱신 시작');
      
      // 1. 자동 로그인 시도 (UI 없이)
      GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
      
      if (currentUser == null) {
        logger.e('자동 로그인 실패. 로그인 화면으로 이동 필요.');
        return {'success': false, 'error': '재로그인이 필요합니다'};
      }

      // 2. 인증 정보 다시 가져오기 (자동으로 갱신됨)
      final GoogleSignInAuthentication auth = await currentUser.authentication;
      
      logger.i('구글 토큰 갱신 성공: ${currentUser.email}');
      
      return {
        'success': true,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      };
    } catch (error) {
      logger.e('구글 토큰 갱신 실패: $error');
      return {'success': false, 'error': error.toString()};
    }
  }
}

