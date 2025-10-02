import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  
  // 사용자 정보는 Kakao API 응답을 통해 받아오므로 nullable로 설정
  final KakaoUserInfo? kakaoUserInfo;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.kakaoUserInfo,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class KakaoUserInfo {
  final int? id;
  final String? email;
  final String? nickname;
  final String? profileImageUrl;
  final Map<String, dynamic>? kakaoAccount;

  const KakaoUserInfo({
    this.id,
    this.email,
    this.nickname,
    this.profileImageUrl,
    this.kakaoAccount,
  });

  factory KakaoUserInfo.fromJson(Map<String, dynamic> json) =>
      _$KakaoUserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$KakaoUserInfoToJson(this);
}
