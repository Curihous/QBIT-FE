import 'package:flutter/material.dart';

import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget; // For custom titles like logos
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color contentColor;
  final bool centerTitle;
  final double elevation;
  final Widget? leadingIcon; // For custom back button or other leading icons

  const AppHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.backgroundColor = AppColors.gray0,
    this.contentColor = AppColors.gray900,
    this.centerTitle = false,
    this.elevation = 0,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Row(
            children: [
              // Leading (Back Button or Custom)
              if (showBack || leadingIcon != null)
                Container(
                  width: 40,
                  alignment: Alignment.centerLeft,
                  child: leadingIcon ??
                      GestureDetector(
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.arrow_back,
                          color: contentColor,
                          size: 24,
                        ),
                      ),
                )
              else if (centerTitle)
                // If center title and no back button, add spacer to balance
                const SizedBox(width: 40),

              // Title
              Expanded(
                child: titleWidget ??
                    (title != null
                        ? Tooltip(
                            message: title!,
                            child: Text(
                              title!,
                              style: AppFonts.t2Semibold.copyWith(
                                color: contentColor,
                                fontSize: 18,
                              ),
                              textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : const SizedBox()),
              ),

              // Actions
              if (actions != null) ...actions! else if (centerTitle) const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
