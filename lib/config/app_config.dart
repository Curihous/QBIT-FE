class AppConfig {
  // 카카오 앱 키 
  static const String kakaoNativeAppKey = '4c24647305b6aeb66cb91d758c64399d';
  
  // 카카오 REST API 키 (REST API 방식용)
  static const String kakaoRestApiKey = '4c24647305b6aeb66cb91d758c64399d';
  
  // 백엔드 API 설정
  static const String baseUrl = 'https://api.qbit.o-r.kr';
  static const String backendUrl = 'https://api.qbit.o-r.kr';
  
  // 카카오 OAuth 설정
  static const String kakaoRedirectUri = 'https://api.qbit.o-r.kr/login/oauth2/code/kakao';
  
  // 개발용 로컬호스트 설정
  static const String localhostPort = '5000';
  static const String localhostUrl = 'http://localhost:$localhostPort';
}

