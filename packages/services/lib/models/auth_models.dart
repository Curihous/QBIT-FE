/// 카카오 로그인 요청 모델
class KakaoLoginRequest {
  final String kakaoAccessToken;
  final String userId;
  final String? nickname;
  final String? email;

  KakaoLoginRequest({
    required this.kakaoAccessToken,
    required this.userId,
    this.nickname,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'kakaoAccessToken': kakaoAccessToken,
      'userId': userId,
      'nickname': nickname,
      'email': email,
    };
  }
}

/// 카카오 로그인 응답 모델
class KakaoLoginResponse {
  final String? accessToken;
  final int? expiresIn;
  final bool? isNewUser;
  final int? userId;
  final String? email;
  final String? nickname;

  KakaoLoginResponse({
    this.accessToken,
    this.expiresIn,
    this.isNewUser,
    this.userId,
    this.email,
    this.nickname,
  });

  factory KakaoLoginResponse.fromJson(Map<String, dynamic> json) {
    return KakaoLoginResponse(
      accessToken: json['accessToken'],
      expiresIn: json['expiresIn'],
      isNewUser: json['isNewUser'],
      userId: json['userId'],
      email: json['email'],
      nickname: json['nickname'],
    );
  }
}

/// 토큰 갱신 요청 모델
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

/// 토큰 갱신 응답 모델
class RefreshTokenResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  RefreshTokenResponse({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.message,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      success: json['success'] ?? false,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      message: json['message'],
    );
  }
}

/// 로그아웃 응답 모델
class LogoutResponse {
  final bool success;
  final String? message;

  LogoutResponse({
    required this.success,
    this.message,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}
