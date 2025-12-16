import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 여백 (Spacer로 비율 조정)
                  const Spacer(flex: 3),
              
              // Qbit 로고
              SvgPicture.asset(
                'assets/images/Qbit_logo_intro_primary.svg',
                width: 98,
                height: 43,
              ),
              
              SizedBox(height: context.h(24)),
              
              // 설명 텍스트
              const Text(
                '이론과 실전을 잇는 거래 학습의 시작 —',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.gray900,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.h(8)),
              const Text(
                '큐빗과 함께 나만의 거래 감각을 만들어가요',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.gray900,
                  height: 1.4,
                ),
              ),
              
              // 중간 여백 (Spacer로 비율 조정)
              const Spacer(flex: 2),
              
              // 로그인 버튼들
              Column(
                children: [
                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: context.h(56),
                    child: InkWell(
                      onTap: _isLoading ? null : _handleKakaoLogin,
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/kakao_login_large_wide.png',
                            width: double.infinity,
                            height: context.h(56),
                            fit: BoxFit.contain,
                          ),
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              height: context.h(56),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: context.w(20),
                                  height: context.h(20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: context.h(16)),
                  
                  // 구글 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: context.h(56),
                    child: InkWell(
                      onTap: _isLoading ? null : _handleGoogleLogin,
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SvgPicture.asset(
                            'assets/images/google_login.svg',
                            width: double.infinity,
                            height: context.h(56),
                            fit: BoxFit.contain,
                          ),
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              height: context.h(56),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: context.w(20),
                                  height: context.h(20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // 하단 여백 (Spacer로 비율 조정)
              const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 구글 로그인 처리
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.loginWithGoogle();
      
      if (mounted) {
        if (result?['success'] == true) {
          // 로그인 성공 시 홈 화면으로 이동
          context.go('/home');
        } else {
          // 로그인 실패 시 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('구글 로그인 실패: ${result?['error'] ?? '알 수 없는 오류'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구글 로그인 중 오류가 발생했습니다: $error'),
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

  // 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login();
      
      if (mounted) {
        if (result?['success'] == true) {
          // 로그인 성공 시 홈 화면으로 이동
          context.go('/home');
        } else {
          // 로그인 실패 시 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${result?['error'] ?? '알 수 없는 오류'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 중 오류가 발생했습니다: $error'),
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

}