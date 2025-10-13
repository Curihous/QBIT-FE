import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qbit_services/auth/auth_service.dart';

// 앱 실행 시 뜨는 최초 스플래시 화면 > 2초 후 login_screen으로 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      try {
        // 로그인 상태 확인
        final isLoggedIn = await AuthService.isLoggedIn();
        
        if (isLoggedIn) {
          // 로그인되어 있으면 홈 화면으로 이동
          context.go('/home');
        } else {
          // 로그인되지 않았으면 로그인 화면으로 이동
          context.go('/login');
        }
      } catch (e) {
        // 오류 발생 시 로그인 화면으로 이동
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Qbit',
              style: GoogleFonts.shrikhand(
                fontSize: 60,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}