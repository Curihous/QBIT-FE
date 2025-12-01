import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qbit_shared/screens/splash/splash_screen.dart';
import 'package:qbit_shared/screens/splash/login_screen.dart';
import 'package:qbit_shared/layout/main_layout.dart';
import 'package:qbit_shared/screens/home/home_screen.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/trade/order_history_screen.dart';
import 'package:qbit_shared/screens/trade/order_detail_screen.dart';
import 'package:qbit_shared/screens/trade/stock_search_screen.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_detail_navigation_screen.dart';
import 'package:qbit_shared/screens/trade/alpaca_auth_screen.dart';
import 'package:qbit_shared/screens/report/trade_report_screen.dart';
import 'package:qbit_shared/screens/report/trade_report_intro_screen.dart';
import 'package:qbit_shared/screens/cards/learning_card_detail_screen.dart';
import 'package:qbit_shared/screens/column/column_detail_screen.dart';
import 'package:qbit_shared/screens/portfolio/portfolio_positions_screen.dart';
import 'package:qbit_shared/screens/portfolio/portfolio_position_detail_screen.dart';
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
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/alpaca-auth',
        name: 'alpaca-auth',
        builder: (context, state) => const AlpacaAuthScreen(),
      ),
      GoRoute(
        path: '/order-history',
        name: 'order-history',
        builder: (context, state) {
          final symbol = state.uri.queryParameters['symbol'];
          return OrderHistoryScreen(initialSymbol: symbol);
        },
      ),
      GoRoute(
        path: '/order-detail/:orderId',
        name: 'order-detail',
        builder: (context, state) {
          final orderId = int.tryParse(state.pathParameters['orderId'] ?? '0') ?? 0;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/auth/alpaca/callback',
        name: 'alpaca-callback',
        builder: (context, state) {
          // 알파카 인증 콜백 처리
          final success = state.uri.queryParameters['success'] == 'true';
          
          // 즉시 화면 이동 처리
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              if (success) {
                // 성공 시 홈 화면으로 이동 (네비게이션 화면)
                context.go('/home');
              } else {
                // 실패 시 Alpaca 인증 화면으로 이동
                context.go('/alpaca-auth');
              }
            }
          });
          
          // 로딩 화면 표시
          return Scaffold(
            backgroundColor: AppColors.primaryBG,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '계좌 연동 처리 중...',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        path: '/stock-detail/:symbol',
        name: 'stock-detail',
        builder: (context, state) {
          final symbol = Uri.decodeComponent(state.pathParameters['symbol'] ?? '');
          final name = Uri.decodeComponent(state.uri.queryParameters['name'] ?? '');
          final assetClass = Uri.decodeComponent(state.uri.queryParameters['assetClass'] ?? 'us_equity');
          final binanceSymbol = state.uri.queryParameters['binanceSymbol'] != null
              ? Uri.decodeComponent(state.uri.queryParameters['binanceSymbol']!)
              : null;
          return StockDetailNavigationScreen(
            symbol: symbol,
            name: name,
            assetClass: assetClass,
            binanceSymbol: binanceSymbol,
          );
        },
      ),
      GoRoute(
        path: '/trade-report/:tradeCycleId',
        name: 'trade-report',
        builder: (context, state) {
          final idStr = state.pathParameters['tradeCycleId'] ?? '0';
          final tradeCycleId = int.tryParse(idStr) ?? 0;
          return TradeReportIntroScreen(tradeCycleId: tradeCycleId);
        },
      ),
      GoRoute(
        path: '/trade-report-detail/:tradeCycleId',
        name: 'trade-report-detail',
        builder: (context, state) {
          final idStr = state.pathParameters['tradeCycleId'] ?? '0';
          final tradeCycleId = int.tryParse(idStr) ?? 0;
          return TradeReportScreen(tradeCycleId: tradeCycleId);
        },
      ),
      GoRoute(
        path: '/learning-card/:cardType',
        name: 'learning-card',
        builder: (context, state) {
          final cardType = state.pathParameters['cardType'] ?? '';
          final extractedTags = state.extra as List<String>?;
          return LearningCardDetailScreen(
            cardType: cardType,
            extractedTags: extractedTags,
          );
        },
      ),
      GoRoute(
        path: '/column/:ticker',
        name: 'column-detail',
        builder: (context, state) {
          final ticker = Uri.decodeComponent(state.pathParameters['ticker'] ?? '');
          return ColumnDetailScreen(ticker: ticker);
        },
      ),
      GoRoute(
        path: '/portfolio-positions',
        name: 'portfolio-positions',
        builder: (context, state) => const PortfolioPositionsScreen(),
      ),
      GoRoute(
        path: '/portfolio-positions/detail/:symbol',
        name: 'portfolio-position-detail',
        builder: (context, state) {
          final symbol = Uri.decodeComponent(state.pathParameters['symbol'] ?? '');
          return PortfolioPositionDetailScreen(symbol: symbol);
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
    // (ApiClient가 이미 토큰 재발급을 시도했으나 실패한 경우 발생)
    _tokenExpiredSub = ApiClient.onTokenExpired.listen((_) async {
      if (mounted) {
        print('[AppRouter] 토큰 갱신 실패 - 로그인 화면으로 이동');
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
      backgroundColor: AppColors.primaryBG, // 소프트 배경
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), // 메인 민트색
        ),
      ),
    );
  }
}
