import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_theme.dart';
import 'package:qbit_core/config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleKakaoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // AuthService.login()은 카카오 SDK 로그인 + 백엔드 인증을 모두 처리
      final result = await AuthService.login();
      
      if (result['success'] == true) {
        if (mounted) {
          // 로그인 성공 - 홈 화면으로 이동
          final isNewUser = result['isNewUser'] ?? false;
          if (isNewUser) {
            // 신규 사용자면 환영 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('환영합니다! 회원가입이 완료되었습니다.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          context.go('/home');
        }
      } else {
        if (mounted) {
          String errorMessage = result['error'] ?? '로그인에 실패했습니다';
          if (errorMessage == '사용자 취소') {
            // 사용자가 취소한 경우는 별도 메시지 없이 처리
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // 상단 여백
              const SizedBox(height: 100),
              
              // QBit + 앱 설명 
              Text(
                'QBit',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '앱설명앱설명앱설명',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 130),
              
              // 부엉이 로고 
              SvgPicture.asset(
                'assets/images/home_logo.svg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // 하단 여백 
              const SizedBox(height: 130),
              
              // 카카오 로그인 버튼 (
              SizedBox(
                width: double.infinity,
                height: 60,
                child: InkWell(
                  onTap: _isLoading ? null : _handleKakaoLogin,
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/kakao_login_large_wide.png',
                    width: double.infinity,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              // 하단 여백
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
