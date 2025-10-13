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
  int _currentIndex = 0;

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // 네비게이션 바에서의 라우팅
    switch (index) {
      case 0:
        // 현재 화면
        break;
      case 1:
        // 학습
        context.go('/learning');
        break;
      case 2:
        // 기록
        context.go('/record');
        break;
      case 3:
        // 거래
        context.go('/trade');
        break;
      case 4:
        // 분석
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
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: _onNavItemTap,
      ),
    );
  }
}
