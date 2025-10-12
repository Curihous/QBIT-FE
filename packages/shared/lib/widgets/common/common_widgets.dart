import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// 로딩 위젯
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
              strokeWidth: 2.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppFonts.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 에러 위젯
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppFonts.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 빈 상태 위젯
class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Widget? action;

  const EmptyWidget({
    super.key,
    required this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppFonts.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 구분선 위젯
class DividerWidget extends StatelessWidget {
  final double? height;
  final Color? color;
  final EdgeInsets? margin;

  const DividerWidget({
    super.key,
    this.height,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 1,
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: color ?? AppColors.border,
    );
  }
}

/// 스페이서 위젯
class SpacerWidget extends StatelessWidget {
  final double height;

  const SpacerWidget({
    super.key,
    this.height = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

/// 하단 네비게이션 바 위젯
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    final navBarHeight = screenHeight * 0.1; 
    final horizontalPadding = screenWidth * 0.04; 
    final verticalPadding = navBarHeight * 0.08; 
    
    return Container(
      height: navBarHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, 
          vertical: verticalPadding,
        ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                iconPath: 'assets/images/nav_icons/home.svg',
                label: '홈',
                index: 0,
                isSelected: currentIndex == 0,
                screenHeight: screenHeight,
              ),
              _buildNavItem(
                iconPath: 'assets/images/nav_icons/book.svg',
                label: '학습',
                index: 1,
                isSelected: currentIndex == 1,
                screenHeight: screenHeight,
              ),
              _buildNavItem(
                iconPath: 'assets/images/nav_icons/record.svg',
                label: '기록',
                index: 2,
                isSelected: currentIndex == 2,
                screenHeight: screenHeight,
              ),
              _buildNavItem(
                iconPath: 'assets/images/nav_icons/chart.svg',
                label: '거래',
                index: 3,
                isSelected: currentIndex == 3,
                screenHeight: screenHeight,
              ),
              _buildNavItem(
                iconPath: 'assets/images/nav_icons/analysis.svg',
                label: '분석',
                index: 4,
                isSelected: currentIndex == 4,
                screenHeight: screenHeight,
              ),
            ],
          ),
        ),
    );
  }

  IconData _getDefaultIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.book;
      case 2:
        return Icons.history;
      case 3:
        return Icons.trending_up;
      case 4:
        return Icons.analytics;
      default:
        return Icons.circle;
    }
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required int index,
    required bool isSelected,
    required double screenHeight,
  }) {
   
    // 화면 높이에 비례하게 설정(아이콘, 텍스트, 간격)
    final iconSize = screenHeight * 0.03;
    final fontSize = screenHeight * 0.015;
    final spacing = screenHeight * 0.004;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 0, bottom: 4, left: 4, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          Icon(
            _getDefaultIcon(index),
            size: iconSize,
            color: isSelected ? AppColors.gray900 : AppColors.gray300,
          ),
          SizedBox(height: spacing),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: fontSize,
                color: isSelected ? AppColors.gray900 : AppColors.gray300,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
