import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qbit_shared/screens/splash/splash_screen.dart';
import 'package:qbit_shared/screens/splash/login_screen.dart';
import 'package:qbit_shared/screens/home/home_screen.dart';
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
        path: '/trade',
        name: 'trade',
        builder: (context, state) => const TradeScreen(),
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
      GoRoute(
        path: '/learning',
        name: 'learning',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('학습 페이지')),
        ),
      ),
      GoRoute(
        path: '/record',
        name: 'record',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('기록 페이지')),
        ),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('분석 페이지')),
        ),
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
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    _setupTokenExpiredListener();
  }

  void _setupTokenExpiredListener() {
    // 토큰 만료 이벤트 리스너 설정
    ApiClient.onTokenExpired.listen((_) {
      if (mounted) {
        // 토큰 만료 시 로그인 화면으로 이동
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
        if (mounted) {
          context.go('/splash');
        }
      } else {
        // 재실행 - 로그인 상태 확인 후 적절한 화면으로 이동
        final isLoggedIn = await AuthService.isLoggedIn();
          
        if (mounted) {
          if (isLoggedIn) {
            // 로그인되어 있으면 홈 화면으로
            context.go('/home');
          } else {
            // 로그인되지 않았으면 스플래시 화면으로
            context.go('/splash');
          }
        }
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
    return const Scaffold(
      backgroundColor: AppColors.background, // 소프트 배경
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), // 메인 민트색
        ),
      ),
    );
  }
}
