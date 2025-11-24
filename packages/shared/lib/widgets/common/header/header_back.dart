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

  const HeaderBack({
    super.key,
    this.title,
    this.onBackPressed,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Container(
        width: context.screenWidth,
        height: kToolbarHeight,
        padding: EdgeInsets.symmetric(horizontal: context.w(20)),
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
              Text(
                title!,
                style: AppFonts.t2Semibold, 
              ),
            ],
          ],
        ),
      ),
    );
  }
}

