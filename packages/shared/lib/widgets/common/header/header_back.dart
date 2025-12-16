import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class HeaderBack extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  /// 헤더 오른쪽에 표시할 추가 위젯들 (취소, 완료)
  final List<Widget>? actions;
  /// 검색 아이콘 표시 여부
  final bool showSearchIcon;
  /// 검색 아이콘 클릭 콜백
  final VoidCallback? onSearchPressed;

  const HeaderBack({
    super.key,
    this.title,
    this.onBackPressed,
    this.backgroundColor,
    this.actions,
    this.showSearchIcon = false,
    this.onSearchPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.gray0,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Container(
        width: double.infinity,
        height: kToolbarHeight,
        padding: EdgeInsets.only(left: context.w(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onBackPressed ?? () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: SvgPicture.asset(
                'assets/icons/navigation/top-nav-back.svg',
                width: context.w(20),
                height: context.h(20),
                fit: BoxFit.contain,
              ),
            ),
            if (title != null) ...[
              SizedBox(width: context.w(15)),
              Expanded(
                child: Text(
                title!,
                style: AppFonts.t2Semibold, 
              ),
              ),
            ] else
              const Spacer(),
            if (showSearchIcon) ...[
              SizedBox(width: context.w(8)),
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: AppColors.gray900,
                ),
                onPressed: onSearchPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: context.w(16)),
            ],
            if (actions != null) ...[
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(right: context.w(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

