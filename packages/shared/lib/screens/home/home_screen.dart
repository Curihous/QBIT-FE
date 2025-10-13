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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '구현예정',
              style: AppFonts.titleLarge.copyWith(
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'TODO: 포트폴리오 연동\n- 보유자산 조회 API 연동\n- 포트폴리오 차트 구현\n- 수익률 계산 및 표시',
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
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
