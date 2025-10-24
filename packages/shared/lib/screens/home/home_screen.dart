import 'package:flutter/material.dart';
import 'package:qbit_shared/widgets/common/bottom_navigation_bar.dart';
import 'package:qbit_shared/widgets/common/header_home.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContentScreen(),
    const StudyScreen(),
    const RecordScreen(),
    const TradeScreen(),
    const MyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 노현선님을 위한 소식 섹션
            Container(
              width: double.infinity,
              height: 276,
              decoration: const BoxDecoration(
                color: AppColors.secondaryMain, // 노란색 배경
              ),
              child: Stack(
                children: [
                  // 제목
                  Positioned(
                    left: 20,
                    top: 25,
                    child: Text(
                      '10월 21일, 노현선님을 위한 소식',
                      style: AppFonts.t2Bold.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  // 뉴스 카드
                  Positioned(
                    left: 20,
                    top: 62,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/column');
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 214,
                        decoration: const ShapeDecoration(
                          color: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 뉴스 내용 배경
                  Positioned(
                    left: 20,
                    top: 218,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/column');
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: AppColors.gray30,
                        ),
                      ),
                    ),
                  ),
                  // 뉴스 제목
                  Positioned(
                    left: 38,
                    top: 228,
                    child: Text(
                      '🪙 이더리움, 다시 뜨거워질까?',
                      style: AppFonts.b1Semibold.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  // 뉴스 부제목
                  Positioned(
                    left: 38,
                    top: 251,
                    child: Text(
                      '불붙는 코인 시장, 유동성 신호등이 켜졌다.',
                      style: AppFonts.c2.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 추천 이론 학습 섹션 (구현 예정)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '추천 이론 학습',
                    style: AppFonts.t2Semibold.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '구현 예정',
                        style: AppFonts.b1Regular.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
