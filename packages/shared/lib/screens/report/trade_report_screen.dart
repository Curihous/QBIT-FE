import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/widgets/common/common_widgets.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';
import 'package:qbit_shared/widgets/common/button/big_black_button.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

class TradeReportScreen extends StatelessWidget {
  const TradeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '매매 리포트',
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // 첫 번째 텍스트 - 보유 주식 전량 매도 완료
            Positioned(
              left: 22,
              top: 80,
              child: Text(
                '보유 주식 전량 매도 완료',
                style: AppFonts.b1Regular.copyWith(color: AppColors.gray900),
              ),
            ),
            
            // 두 번째 텍스트 - 이번 매매, 전략적으로 어땠을까요?
            Positioned(
              left: 22,
              top: 110,
              child: SizedBox(
                width: 342,
                child: Text(
                  '이번 매매, 전략적으로 어땠을까요?\n지금 리포트를 확인해보세요.',
                  style: AppFonts.t2Bold.copyWith(
                    color: AppColors.gray900,
                    height: 1.6, // lineheight 조정
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            
            // 올빼미 리포트 캐릭터 (중앙 배치, 크기 증가)
            Positioned(
              left: 0,
              right: 0,
              top: 200,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/characters/owl-report.svg',
                  width: 300,
                  height: 300,
                ),
              ),
            ),
            
            // AI 리포트 확인 버튼
            Positioned(
              left: 16,
              right: 16,
              top: 580,
              child: BigBlackButton(
                text: 'AI 리포트 확인',
                onPressed: () {
                  // TODO: AI 리포트 확인 로직 구현
                  _handleReportCheck(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AI 리포트 확인 처리
  void _handleReportCheck(BuildContext context) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 목업 데이터 로딩 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      
      // 로딩 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        // AI 리포트 상세 페이지로 이동
        context.push('/ai-report-detail');
      }
    } catch (error) {
      // 로딩 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리포트 확인 중 오류가 발생했습니다: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
