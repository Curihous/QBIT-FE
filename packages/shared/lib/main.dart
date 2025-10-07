import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:qbit_core/config/app_config.dart';
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_shared/theme/app_theme.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_shared/router/app_router.dart';

void runQbitApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 초기화
  try {
    await EnvConfig.initialize();
    print('환경 변수 초기화 완료');
  } catch (e) {
    print('환경 변수 초기화 실패: $e');
    // 개발 환경에서는 계속 진행
  }
  
  // 카카오 SDK 초기화
  try {
    KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);
    print('카카오 SDK 초기화 완료');
  } catch (e) {
    print('카카오 SDK 초기화 실패: $e');
  }
  
  // 개발자 모드 에러 로그 활성화
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('ERROR: Flutter Error: ${details.exception}');
    print('STACK: ${details.stack}');
  };
  
  // Dart 에러 처리
  PlatformDispatcher.instance.onError = (error, stack) {
    print('ERROR: Dart Error: $error');
    print('STACK: $stack');
    return true;
  };
  
  runApp(const QbitApp());
}

void main() => runQbitApp();

class QbitApp extends StatefulWidget {
  const QbitApp({super.key});

  @override
  State<QbitApp> createState() => _QbitAppState();
}

class _QbitAppState extends State<QbitApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // 앱이 이미 실행 중일 때 URL 처리
    _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Deep Link 받음 (앱 실행 중): $uri');
        print('🔗 Query Parameters: ${uri.queryParameters}');
        // 카카오 SDK가 자동으로 Deep Link 처리
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );

    // 앱이 종료된 상태에서 URL로 실행될 때 처리
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        print('🔗 Deep Link 받음 (앱 시작): $uri');
        print('🔗 Query Parameters: ${uri.queryParameters}');
        // 카카오 SDK가 자동으로 Deep Link 처리
      } else {
        print('ℹ️ 초기 Deep Link 없음');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
