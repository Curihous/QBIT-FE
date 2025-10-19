import 'package:flutter/material.dart';
import 'package:qbit_core/config/app_config.dart';
import 'package:qbit_shared/router/app_router.dart';

/// QBit 앱의 메인 위젯
class QbitApp extends StatelessWidget {
  const QbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

