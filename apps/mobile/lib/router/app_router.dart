import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/login_success_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/debug/debug_screen.dart';
import '../screens/investment/investment_screen.dart';
import '../services/api_service.dart';

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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/oauth',
        name: 'oauth',
        builder: (context, state) => const LoginSuccessScreen(), // 성공 화면으로 변경
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
      GoRoute(
        path: '/investment',
        name: 'investment',
        builder: (context, state) => const InvestmentScreen(),
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
  }

  Future<void> _checkFirstLaunch() async {
    try {
      // 웹 환경에서는 shared_preferences만 사용
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final isFirstLaunch = prefs.getString(AppRouter._isFirstLaunchKey);
        
        if (isFirstLaunch == null) {
          // 최초 실행 - 로그인 화면으로 이동하고 플래그 설정
          await prefs.setString(AppRouter._isFirstLaunchKey, 'false');
          if (mounted) {
            context.go('/login');
          }
        } else {
          // 재실행 - 로그인 상태 확인 후 적절한 화면으로 이동
          final apiService = ApiService();
          final isLoggedIn = await apiService.isLoggedIn();
          
          if (mounted) {
            if (isLoggedIn) {
              context.go('/home');
            } else {
              context.go('/login');
            }
          }
        }
      } else {
        // 모바일/데스크톱 환경에서는 flutter_secure_storage 사용
        final isFirstLaunch = await AppRouter._storage.read(key: AppRouter._isFirstLaunchKey);
        
        if (isFirstLaunch == null) {
          // 최초 실행 - 로그인 화면으로 이동하고 플래그 설정
          await AppRouter._storage.write(key: AppRouter._isFirstLaunchKey, value: 'false');
          if (mounted) {
            context.go('/login');
          }
        } else {
          // 재실행 - 로그인 상태 확인 후 적절한 화면으로 이동
          final apiService = ApiService();
          final isLoggedIn = await apiService.isLoggedIn();
          
          if (mounted) {
            if (isLoggedIn) {
              context.go('/home');
            } else {
              context.go('/login');
            }
          }
        }
      }
    } catch (e) {
      // 오류 발생 시 로그인 화면으로 이동
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE6F4F1), // 소프트 배경
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C9A7)), // 메인 민트색
        ),
      ),
    );
  }
}
