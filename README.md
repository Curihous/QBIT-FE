# QBIT-FE

## 요구사항
- Flutter SDK (3.6.0 이상)
- Dart SDK
- iOS: Xcode, CocoaPods
- Android: Android Studio, Android SDK

## 환경 설정

### 환경 변수 설정
1. `.env.example` 파일을 `.env`로 복사합니다:
   ```bash
   cp .env.example .env
   ```

2. `.env` 파일에서 실제 값들을 설정합니다:
   - `KAKAO_NATIVE_APP_KEY`: 카카오 네이티브 앱 키
   - `BACKEND_URL`: 백엔드 API URL
   - 기타 필요한 환경 변수들

### 보안 주의사항
⚠️ **중요**: 실제 환경 변수는 다음 방법으로 관리해야 합니다:
- **개발 환경**: 로컬 `.env` 파일 사용 (Git에 커밋하지 않음)
- **프로덕션 환경**: 
  - iOS: Keychain 사용
  - Android: Keystore 사용
  - CI/CD: 환경 변수로 주입

`.env` 파일은 민감한 정보를 포함하므로 Git에 커밋하지 마세요.

## 빌드 명령어

```bash
# 의존성 설치
flutter pub get

# iOS 실행
flutter run -d [iOS 디바이스 ID]

# Android 실행
flutter run -d [Android 디바이스 ID]
```