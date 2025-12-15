# QBIT-FE

<img width="2352" height="3309" alt="22-큐리포스-포스터파일-png" src="https://github.com/user-attachments/assets/ae69fc8d-0b65-4a0d-85ec-1acfaaf9c971" />

## 프로젝트 소개

QBIT-FE는 Flutter 기반의 모바일 애플리케이션입니다. iOS와 Android 플랫폼을 지원하며, 주식 거래 및 투자 관련 기능을 제공합니다.

### 주요 기능
- 주식 검색 및 거래
- 실시간 주가 정보
- 매매 리포트 작성
- 투자 기록 관리
- 소셜 로그인 (카카오, 구글)

## 요구사항

- Flutter SDK 3.8.0 이상
- Dart SDK 3.6.0 이상
- iOS: Xcode 14.0 이상, CocoaPods
- Android: Android Studio, Android SDK (API Level 21 이상)

## 설치 및 실행

#### 1. 저장소 클론
```bash
git clone https://github.com/Curihous/QBIT-FE.git
cd QBIT-FE
```

#### 2. 의존성 설치
```bash
flutter pub get
cd packages/core && flutter pub get
cd packages/services && flutter pub get
cd packages/shared && flutter pub get
cd ios && pod install
```

#### 3. 환경 변수 설정
`assets/env/.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
BACKEND_URL=https://api.qbit.o-r.kr
BACKEND_API_VERSION=v1
KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id
WEBSOCKET_URL=ws://15.165.205.46:8081/ws/websocket
```

#### 4. iOS 추가 설정 (iOS 개발 시)
```bash
# Firebase Console에서 GoogleService-Info.plist 다운로드 후
# assets/env/GoogleService-Info.plist 또는 프로젝트 루트에 배치
./scripts/setup_ios_google_service.sh
./scripts/update_ios_kakao_key.sh
```

#### 5. 실행
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```


## 프로젝트 구조

```
QBIT-FE/
├── lib/                    # 메인 애플리케이션 코드
│   └── main.dart          # 앱 진입점
├── packages/               # 모노레포 패키지
│   ├── core/              # 핵심 설정 및 모델
│   ├── services/          # 공통 서비스 (API, 인증, WebSocket)
│   └── shared/            # 공유 UI 컴포넌트
├── assets/                # 리소스 파일 (이미지, 아이콘, 폰트)
├── scripts/               # 빌드 및 설정 스크립트
├── ios/                   # iOS 네이티브 코드
├── android/               # Android 네이티브 코드
└── test/                  # 테스트 파일
```

### 주요 패키지
- **qbit_core**: 핵심 설정 및 모델 정의
- **qbit_services**: 공통 서비스 레이어 (REST API, WebSocket, 인증)
- **qbit_shared**: 공유 UI 컴포넌트

<br>

## 사용된 오픈소스 라이브러리

- **Flutter SDK**, **Dart SDK**: Flutter 프레임워크
- **go_router**: 선언적 라우팅
- **flutter_svg**: SVG 이미지 렌더링
- **fl_chart**: 차트 라이브러리
- **kakao_flutter_sdk**: 카카오 로그인 SDK
- **google_sign_in**: 구글 로그인
- **dio**: HTTP 클라이언트
- **web_socket_channel**: WebSocket 클라이언트
- **riverpod_generator**: 상태 관리 코드 생성
- **flutter_secure_storage**: 보안 저장소
- **build_runner**: 코드 생성 도구
- **json_serializable**: JSON 직렬화

전체 의존성 목록: `pubspec.yaml` 파일 참조
