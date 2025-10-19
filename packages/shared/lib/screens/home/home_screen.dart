import 'package:flutter/material.dart';
import 'package:qbit_shared/widgets/common/bottom_navigation_bar.dart';
import 'package:qbit_shared/widgets/common/header_home.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

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
      backgroundColor: Colors.white,
      appBar: const TopAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '구현예정',
              style: AppFonts.t1Bold.copyWith(
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'TODO: 포트폴리오 연동\n- 보유자산 조회 API 연동\n- 포트폴리오 차트 구현\n- 수익률 계산 및 표시',
              style: AppFonts.b1Regular.copyWith(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
