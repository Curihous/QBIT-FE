import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 수정 필요

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF00C9A7),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: '학습',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: '기록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up_outlined),
          activeIcon: Icon(Icons.trending_up),
          label: '거래',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: '분석',
        ),
      ],
    );
  }
}

class NavigationHelper {
  static void navigateToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        // 학습 탭
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학습 화면 준비 중')),
        );
        break;
      case 2:
        context.go('/record');
        break;
      case 3:
        context.go('/trade');
        break;
      case 4:
        // 분석 탭
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('분석 화면 준비 중')),
        );
        break;
    }
  }
}
