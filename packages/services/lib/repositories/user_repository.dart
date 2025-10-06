import 'package:qbit_core/models/user.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';
import '../api/api_service.dart';
import '../storage/storage_service.dart';

/// 사용자 관련 Repository
class UserRepository {
  final UserApiService _userApiService = UserApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  /// 현재 사용자 정보 조회
  Future<User> getCurrentUser() async {
    try {
      return await _userApiService.getCurrentUser();
    } catch (e) {
      if (e is ApiException) {
        // API 오류 시 로컬 저장소에서 조회 시도
        final localUserInfo = await _localStorage.getUserInfo();
        if (localUserInfo != null) {
          // 로컬 데이터를 User 객체로 변환 (실제 구현 필요)
          throw ApiException(
            message: '네트워크 오류로 인한 사용자 정보 조회 실패',
          );
        }
      }
      rethrow;
    }
  }

  /// 사용자 정보 업데이트
  Future<User> updateUser(Map<String, dynamic> userData) async {
    try {
      final updatedUser = await _userApiService.updateUser(userData);
      
      // 성공 시 로컬 저장소에도 업데이트
      await _localStorage.saveUserInfo(updatedUser.toJson());
      
      return updatedUser;
    } catch (e) {
      throw ApiException(
        message: '사용자 정보 업데이트 실패: $e',
      );
    }
  }

  /// 로컬 사용자 정보 조회
  Future<Map<String, dynamic>?> getLocalUserInfo() async {
    return await _localStorage.getUserInfo();
  }

  /// 로컬 사용자 정보 저장
  Future<void> saveLocalUserInfo(Map<String, dynamic> userInfo) async {
    await _localStorage.saveUserInfo(userInfo);
  }

  /// 로컬 사용자 정보 삭제
  Future<void> clearLocalUserInfo() async {
    await _localStorage.clearAll();
  }
}
