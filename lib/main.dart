import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:app_links/app_links.dart';
import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/url_handler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(
    nativeAppKey: AppConfig.kakaoNativeAppKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // 앱이 이미 실행 중일 때 URL 처리
    _appLinks.uriLinkStream.listen((Uri uri) {
      UrlHandlerService.handleIncomingUrl(uri.toString());
    }, onError: (err) {
      print('Deep link error: $err');
    });

    // 앱이 종료된 상태에서 URL로 실행될 때 처리
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        UrlHandlerService.handleIncomingUrl(uri.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QBIT',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}