import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
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
      bool success = await KakaoAuthService.login();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카카오 로그인 성공!')),
          );
          context.go('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카카오 로그인 실패')),
          );
        }
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
              // 중앙 콘텐츠
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고/브랜딩
                    Text(
                      AppConfig.appName,
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConfig.appDescription,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: 60), // 더 큰 간격
                    
                    // 올빼미 캐릭터 일러스트
                    Image.asset(
                      'assets/images/character1.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain, // 이미지 비율 유지
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지 로드 실패 시 기본 아이콘 표시
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 80), // 더 큰 여백
                    
                    // 카카오 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleKakaoLogin,
                        borderRadius: BorderRadius.circular(12),
                        child: _isLoading
                            ? Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.kakaoYellow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  ),
                                ),
                              )
                            : Image.asset(
                                'assets/images/kakao_login_large_wide.png',
                                width: double.infinity,
                                height: 60, // 약간 더 높게
                                fit: BoxFit.contain, // 비율 유지하면서 화질 개선
                                errorBuilder: (context, error, stackTrace) {
                                  // 이미지 로드 실패 시 기본 버튼 표시
                                  return Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.kakaoYellow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '카카오로 로그인',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 디버그 버튼 (개발용)
              TextButton(
                onPressed: () {
                  context.go('/debug');
                },
                child: const Text(
                  '디버그 화면',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
