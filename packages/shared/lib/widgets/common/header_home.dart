import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onAlarmPressed;
  final VoidCallback? onSettingPressed;

  const TopAppBar({
    super.key,
    this.onAlarmPressed,
    this.onSettingPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Container(
        width: context.screenWidth,
        height: context.h(28),
        padding: EdgeInsets.symmetric(horizontal: context.w(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/navigation/top-nav-QBIT-text-logo.svg',
              height: context.h(28),
              fit: BoxFit.contain,
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

