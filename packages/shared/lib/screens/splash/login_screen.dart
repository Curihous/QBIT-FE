import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 250),
              
              // Qbit 로고
              Text(
                'Qbit',
                style: GoogleFonts.shrikhand(
                  fontSize: 44,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 설명 텍스트
              const Text(
                '이론과 실전을 잇는 거래 학습의 시작 —',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.gray900,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '큐빗과 함께 나만의 거래 감각을 만들어가요',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.gray900,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 170), // 버튼 위치 조절 (값 커질수록 위로)
              
              // 로그인 버튼들
              Column(
                children: [
                  // 카카오 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleKakaoLogin,
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/images/kakao_login_large_wide.png',
                            width: double.infinity,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
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
                  
                  const SizedBox(height: 16),
                  
                  // 구글 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleGoogleLogin,
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          SvgPicture.asset(
                            'assets/images/google_login.svg',
                            width: double.infinity,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                          if (_isLoading)
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
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
              
              const SizedBox(height: 60),
                ],
              ),
            ),
            
            // 테스트 로그인 버튼 (좌쪽 상단)
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _handleTestLogin,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🧪 테스트',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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

  // 테스트 로그인 처리 (.env의 KAKAO_TEST_ACCESS_TOKEN 사용)
  Future<void> _handleTestLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.loginWithTestToken();
      
      if (mounted) {
        if (result['success'] == true) {
          // 로그인 성공
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('테스트 로그인 성공! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          context.go('/home');
        } else {
          // 로그인 실패
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('테스트 로그인 실패: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 로그인 중 오류: $error'),
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