# QBIT-FE

QBIT 모바일 애플리케이션 - Flutter 기반 주식 거래 앱

## 프로젝트 구조

```
QBIT-FE/
├── lib/                    # 메인 앱 코드
├── packages/
│   ├── core/              # 핵심 설정 및 유틸리티
│   ├── services/          # API 서비스 및 데이터 모델
│   └── shared/            # 공통 UI 컴포넌트 및 화면
├── assets/                # 이미지, 폰트 등 리소스
└── assets/env/            # 환경 변수 파일
```

## 요구사항
- Flutter SDK (3.8.0 이상)
- Dart SDK
- iOS: Xcode, CocoaPods
- Android: Android Studio, Android SDK

## 개발 가이드

### 초기 설정
```bash
# 의존성 설치
flutter pub get
```

### 실행
```bash
# iOS 실행
flutter run -d [iOS 디바이스 ID]

# Android 실행
flutter run -d [Android 디바이스 ID]

# 핫 리로드 개발
flutter run --hot
```

### 개발 브랜치
- `feature/trade`: 거래 기능 개발
- `feature/login`: 로그인 기능 개발
