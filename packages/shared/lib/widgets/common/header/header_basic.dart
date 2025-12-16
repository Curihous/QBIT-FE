import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class HeaderBasic extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAlarmPressed;
  final VoidCallback? onSettingPressed;

  const HeaderBasic({
    super.key,
    required this.title,
    this.onAlarmPressed,
    this.onSettingPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.gray0,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      surfaceTintColor: AppColors.gray0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Container(
        width: context.screenWidth,
        height: context.h(28),
        padding: EdgeInsets.only(left: context.w(20), right: context.w(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppFonts.t1Bold,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/navigation/top-nav-alarm.svg',
                    height: context.h(26),
                    fit: BoxFit.contain,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onAlarmPressed ?? () {},
                ),
                SizedBox(width: context.w(0)),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/navigation/top-nav-setting.svg',
                    height: context.h(26),
                    fit: BoxFit.contain,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onSettingPressed ?? () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
