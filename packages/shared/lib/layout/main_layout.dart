import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/widgets/common/nav/bottom_navigation_bar.dart';
import 'package:qbit_shared/screens/home/home_screen.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

/// 하단 네비게이션을 관리하는 메인 레이아웃
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StudyScreen(),
    const RecordScreen(),
    const TradeScreen(),
    const MyScreen(),
  ];

  Future<void> _navigateToWriteScreen() async {
    final orderId = await context.push<int>('/record/order-selection');
    
    if (orderId != null) {
      // 주문 선택 후 기록 작성 화면으로 이동
      await context.push('/record/write', extra: orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          // 기록 화면일 때만 플로팅 버튼 표시 (하단바 위에 배치)
          if (_currentIndex == 2)
            Positioned(
              right: context.w(16),
              bottom: MediaQuery.of(context).padding.bottom + context.h(72) + context.h(16),
              child: GestureDetector(
                onTap: _navigateToWriteScreen,
                child: SvgPicture.asset(
                  'assets/icons/record/new-record-floating.svg',
                  width: context.w(76),
                  height: context.h(76),
                  fit: BoxFit.contain,
                ),
              ),
            ),
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

