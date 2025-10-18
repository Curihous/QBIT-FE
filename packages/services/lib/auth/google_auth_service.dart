import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

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
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // 구글 로그인 실행
  static Future<Map<String, dynamic>?> login() async {
    try {
      logger.i('구글 로그인 시작');
      
      // 기존 로그인 확인
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      if (currentUser == null) {
        // 새로운 로그인 시도
        currentUser = await _googleSignIn.signIn();
      }
      
      if (currentUser == null) {
        logger.w('사용자가 구글 로그인을 취소했습니다');
        return {'success': false, 'error': '사용자 취소'};
      }

      logger.i('구글 로그인 성공: ${currentUser.email}');

      // 인증 정보 가져오기
      final GoogleSignInAuthentication auth = await currentUser.authentication;
      
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
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      if (currentUser == null) {
        logger.w('로그인된 구글 사용자가 없습니다');
        return null;
      }

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
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      if (currentUser == null) {
        logger.w('로그인된 구글 사용자가 없습니다');
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

  // 토큰 갱신
  static Future<Map<String, dynamic>?> refreshToken() async {
    try {
      logger.i('구글 토큰 갱신 시작');
      
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      
      if (currentUser == null) {
        logger.e('갱신할 구글 사용자가 없습니다');
        return {'success': false, 'error': '갱신할 사용자가 없습니다'};
      }

      // 인증 정보 다시 가져오기 (자동으로 갱신됨)
      final GoogleSignInAuthentication auth = await currentUser.authentication;
      
      logger.i('구글 토큰 갱신 성공');
      
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

