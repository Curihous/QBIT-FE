import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 수정 필요

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
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
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: '투자',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_outlined),
          activeIcon: Icon(Icons.edit),
          label: '기록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
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
        context.go('/investment');
        break;
      case 3:
        // 기록 탭
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록 화면 준비 중')),
        );
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
