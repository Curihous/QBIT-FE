import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/header/header_basic.dart';
import 'package:qbit_shared/widgets/common/button/big_black_button.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final success = await AuthService.logout();
      
      if (!mounted) return;

      if (success) {
        // 로그인 화면으로 이동 (모든 네비게이션 스택 초기화)
        if (mounted) {
          context.go('/login');
        }
      } else {
        // 로그아웃 실패 시 에러 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그아웃 중 오류가 발생했습니다.'),
              backgroundColor: AppColors.chartRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.chartRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray0,
      appBar: HeaderBasic(
        title: '마이페이지',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: context.h(20)),
            child: Inset.text(
              child: Text(
                '계정 설정',
                style: AppFonts.t2Bold.copyWith(color: AppColors.gray900),
              ),
            ),
          ),
          SizedBox(height: context.h(24)),
          Inset.block(
            child: BigBlackButton(
              text: '로그아웃',
              onPressed: _isLoggingOut ? null : _handleLogout,
              isLoading: _isLoggingOut,
            ),
          ),
        ],
      ),
    );
  }
}