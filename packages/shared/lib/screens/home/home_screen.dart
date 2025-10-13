import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/common/common_widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Derive the selected tab index from the current GoRouter location
  int _getCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/learning')) return 1;
    if (location.startsWith('/record')) return 2;
    if (location.startsWith('/trade')) return 3;
    if (location.startsWith('/analysis')) return 4;
    return 0;
  }

  void _onNavItemTap(int index) {
    // 네비게이션 바에서의 라우팅
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/learning');
        break;
      case 2:
        context.go('/record');
        break;
      case 3:
        context.go('/trade');
        break;
      case 4:
        context.go('/analysis');
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: SvgPicture.asset(
                'assets/images/Qbit_logo.svg',
                width: 50,
                height: 25,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // 알림 기능
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // 설정 기능
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: 홈 화면 UI 구현
            // - PortfolioSummary 위젯 (포트폴리오 요약)
            // - RecentTransactions 위젯 (최근 거래 내역)
            // - MarketOverview 위젯 (시장 개요)
            // - QuickActions 위젯 (빠른 액션 버튼들)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64.0,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    '홈 화면',
                    style: AppFonts.titleLarge.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'TODO: 홈 화면 UI 구현 예정',
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    '구현 예정 기능:\n• 포트폴리오 요약\n• 최근 거래 내역\n• 시장 개요\n• 빠른 액션',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: _onNavItemTap,
      ),
    );
  }
}
