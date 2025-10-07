import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qbit_shared/screens/auth/login_screen.dart';
import 'package:qbit_shared/screens/home/home_screen.dart';
import 'package:qbit_services/auth/auth_service.dart';

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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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
      // 모바일 환경: flutter_secure_storage 사용
      final storage = FlutterSecureStorage();
      final isFirstLaunch = await storage.read(key: AppRouter._isFirstLaunchKey);
      
      if (isFirstLaunch == null) {
        // 최초 실행 - 로그인 화면으로 이동하고 플래그 설정
        await storage.write(key: AppRouter._isFirstLaunchKey, value: 'false');
        if (mounted) {
          context.go('/login');
        }
      } else {
        // 재실행 - 로그인 상태 확인 후 적절한 화면으로 이동
        final isLoggedIn = await AuthService.isLoggedIn();
          
        if (mounted) {
          if (isLoggedIn) {
            // 로그인되어 있으면 홈 화면으로
            context.go('/home');
          } else {
            // 로그인되지 않았으면 로그인 화면으로
            context.go('/login');
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
