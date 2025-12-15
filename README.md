# QBIT-FE

<img width="2352" height="3309" alt="22-큐리포스-포스터파일-png" src="https://github.com/user-attachments/assets/ae69fc8d-0b65-4a0d-85ec-1acfaaf9c971" />

## 📋 목차

- [프로젝트 소개](#프로젝트-소개)
- [기술 스택](#기술-스택)
- [설치 및 실행](#설치-및-실행)
- [프로젝트 구조](#프로젝트-구조)
- [사용한 오픈소스](#사용한-오픈소스)

## 프로젝트 소개

### 문제 정의

최근 주식 투자가 대중화되며 많은 사람들이 투자에 뛰어들고 있습니다. 그러나 한국의 디지털 금융 이해도는 OECD 평균보다 낮은 수준이며, 특히 MZ세대 초보 투자자들은 충분한 기초 지식 없이 투자를 시작하는 경우가 많습니다. 이 과정에서 검증되지 않은 개인 방송이나 단편적인 콘텐츠에 의존해 투자 결정을 내리기도 합니다. 큐빗은 **'초보 투자자들이 올바른 투자 지식과 기준 없이 투자 결정을 내리는 것이 과연 괜찮은가'** 라는 문제의식에서 출발했습니다.

저희 팀은 MVP 단계에서 개발 효율과 서비스 완성도를 고려해 하나의 시장에 집중하기로 했습니다. 미국 주식 시장은 장기적인 우상향 구조를 가지고 있으며, 애플·엔비디아와 같은 글로벌 대표 기업들이 포진해 있어 많은 한국 개인 투자자들이 실제로 참여하고 있는 해외 투자 시장입니다. 또한 Alpaca(미국 주식 모의·실거래 주문 및 계좌 관리를 위한 트레이딩 API), Massive.io(미국 주식의 실시간·과거 가격, 거래량 등 금융 데이터 제공 API) 등 안정적인 API 인프라를 활용할 수 있어 기술적 제약이 상대적으로 적습니다. 이러한 시장 특성과 기술적 환경을 바탕으로 큐빗은 미국 주식 투자에 관심은 있지만 경험과 지식이 부족한 초보 투자자를 타겟 유저로 설정했습니다.

이들은 다음과 같은 어려움을 겪습니다:

1. **투자 학습의 막막함**: 기초 개념조차 몰라서 어디서부터 투자 공부를 시작해야 할지 모름
2. **이론과 실전의 괴리**: 단순 이론 학습은 지루하게 느끼며, 실제 투자와의 연결고리가 부족해 지속적인 학습으로 이어지기 어려움
3. **해외 주식 투자의 어려움**: 해외 종목 뉴스는 영어로 제공되며 국내 기업이 아니어서 낯설기에 핵심 이슈와 종목 간 연관성 파악이 어려움

### 솔루션

큐빗의 **이론학습 → 모의투자 → 보유 종목 뉴스 확인 → 복기(AI 매매 분석 리포트 & 매매 일지)** 의 투자 학습 사이클을 통해, 사용자가 자신만의 기준을 갖춘 성숙한 투자자로 성장할 수 있습니다.

- **카드 형식의 쉬운 이론 학습**: 복잡한 투자 지식을 카드 형식으로 단계별 학습할 수 있도록 구성
- **실시간 시세 기반 모의투자**: 실제 주식 거래 환경과 유사한 UI와 WebSocket 기반 실시간 데이터 스트림
- **AI 매매 분석 리포트**: ChatGPT 기반 모델이 사용자의 매매 패턴과 리스크 요인을 분석하고 추천 이론 학습 제공
- **맞춤 해외 뉴스 칼럼**: 보유 종목과 연관 종목을 분석해 자동으로 맞춤 해외 뉴스를 번역하고 재가공한 컬럼 제공


### 주요 기능
- 주식 검색 및 거래
- 실시간 주가 정보
- 매매 리포트 작성
- 투자 기록 관리
- 소셜 로그인 (카카오, 구글)

## 기술 스택
- Flutter SDK 3.8.0 이상
- Dart SDK 3.6.0 이상
- iOS: Xcode 14.0 이상, CocoaPods
- Android: Android Studio, Android SDK (API Level 21 이상)

<br>

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

<br> 

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

## 사용한 오픈소스

- Flutter SDK, Dart SDK: Flutter 프레임워크
- go_router: 선언적 라우팅
- flutter_svg: SVG 이미지 렌더링
- fl_chart: 차트 라이브러리
- kakao_flutter_sdk: 카카오 로그인 SDK
- google_sign_in: 구글 로그인
- dio: HTTP 클라이언트
- web_socket_channel: WebSocket 클라이언트
- riverpod_generator: 상태 관리 코드 생성
- flutter_secure_storage: 보안 저장소
- build_runner: 코드 생성 도구
- json_serializable: JSON 직렬화

전체 의존성 목록: `pubspec.yaml` 파일 참조
