import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qbit_shared/screens/splash/splash_screen.dart';
import 'package:qbit_shared/screens/splash/login_screen.dart';
import 'package:qbit_shared/screens/home/home_screen.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/trade/alpaca_auth_screen.dart';
import 'package:qbit_shared/screens/trade/stock_search_screen.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/api_client.dart';

class AppRouter {
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const _RootScreen(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/study',
        name: 'study',
        builder: (context, state) => const StudyScreen(),
      ),
      GoRoute(
        path: '/record',
        name: 'record',
        builder: (context, state) => const RecordScreen(),
      ),
      GoRoute(
        path: '/trade',
        name: 'trade',
        builder: (context, state) => const TradeScreen(),
      ),
      GoRoute(
        path: '/my',
        name: 'my',
        builder: (context, state) => const MyScreen(),
      ),
      GoRoute(
        path: '/alpaca-auth',
        name: 'alpaca-auth',
        builder: (context, state) => const AlpacaAuthScreen(),
      ),
      GoRoute(
        path: '/stock/:symbol',
        name: 'stock-search',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? '';
          return StockSearchScreen(symbol: symbol.isEmpty ? null : symbol);
        },
      ),
    ],
  );
}

class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  StreamSubscription<void>? _tokenExpiredSub;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _setupTokenExpiredListener();
  }

  @override
  void dispose() {
    _tokenExpiredSub?.cancel();
    super.dispose();
  }

  void _setupTokenExpiredListener() {
    // 토큰 만료 이벤트 리스너 설정
    _tokenExpiredSub = ApiClient.onTokenExpired.listen((_) async {
      if (mounted) {
        
        // 먼저 토큰 갱신 시도
        try {
          final refreshed = await AuthService.refreshAccessToken();
          if (refreshed) {
            return; // 갱신 성공하면 로그인 화면으로 이동하지 않음
          }
        } catch (e) {
        }
        
        // 토큰 갱신 실패 시에만 로그인 화면으로 이동
        print('[AppRouter] 로그인 화면으로 이동');
        context.go('/login');
      }
    });
  }

  Future<void> _checkFirstLaunch() async {
    try {
      // 모바일 환경: flutter_secure_storage 사용
      final storage = FlutterSecureStorage();
      final isFirstLaunch = await storage.read(key: AppRouter._isFirstLaunchKey);
      
      if (isFirstLaunch == null) {
        // 최초 실행 - 스플래시 화면으로 이동하고 플래그 설정
        await storage.write(key: AppRouter._isFirstLaunchKey, value: 'false');
      }
      
      // 항상 스플래시 화면으로 먼저 이동
      if (mounted) {
        context.go('/splash');
      }
    } catch (e) {
      // 오류 발생 시 스플래시 화면으로 이동
      if (mounted) {
        context.go('/splash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 소프트 배경
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), // 메인 민트색
        ),
      ),
    );
  }
}
