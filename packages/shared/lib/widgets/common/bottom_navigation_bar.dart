import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'dart:io';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    Widget navigationBar = Container(
      width: context.screenWidth,
      height: context.h(72),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.w(15)),
          topRight: Radius.circular(context.w(15)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: context.w(20),
          right: context.w(20),
          top: context.h(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              icon: currentIndex == 0 
                  ? 'assets/icons/navigation/bottom-nav-home-active.svg'
                  : 'assets/icons/navigation/bottom-nav-home.svg',
              label: '홈',
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              context: context,
              index: 1,
              icon: currentIndex == 1 
                  ? 'assets/icons/navigation/bottom-nav-study-active.svg'
                  : 'assets/icons/navigation/bottom-nav-study.svg',
              label: '학습',
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              context: context,
              index: 2,
              icon: currentIndex == 2 
                  ? 'assets/icons/navigation/bottom-nav-record-active.svg'
                  : 'assets/icons/navigation/bottom-nav-record.svg',
              label: '기록',
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              context: context,
              index: 3,
              icon: currentIndex == 3 
                  ? 'assets/icons/navigation/bottom-nav-invest-active.svg'
                  : 'assets/icons/navigation/bottom-nav-invest.svg',
              label: '거래',
              isActive: currentIndex == 3,
            ),
            _buildNavItem(
              context: context,
              index: 4,
              icon: currentIndex == 4 
                  ? 'assets/icons/navigation/bottom-nav-my-active.svg'
                  : 'assets/icons/navigation/bottom-nav-my.svg',
              label: 'MY',
              isActive: currentIndex == 4,
            ),
          ],
        ),
      ),
    );

    // iOS는 바닥에 붙게, 안드로이드는 SafeArea 사용
    if (isIOS) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: context.h(10), // 고정값으로 바닥에 붙게
        ),
        child: navigationBar,
      );
    } else {
      // 안드로이드는 SafeArea 적용 (시스템 네비게이션 바 고려)
      return SafeArea(child: navigationBar);
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String icon,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Align(
          alignment: Alignment.topCenter,
          child: SvgPicture.asset(
            icon,
            width: context.w(24),
            height: context.h(44),
          ),
        ),
      ),
    );
  }
}

