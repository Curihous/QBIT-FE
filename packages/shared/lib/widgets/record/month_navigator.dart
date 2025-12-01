import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:intl/intl.dart';

/// 월별 네비게이터 위젯
class MonthNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthNavigator({
    super.key,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthText = DateFormat('yyyy.MM').format(selectedDate);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onPreviousMonth,
            child: Icon(
              Icons.chevron_left,
              color: AppColors.gray400,
              size: 24,
            ),
          ),
          SizedBox(width: context.w(16)),
          Text(
            monthText,
            style: AppFonts.t2Bold.copyWith(
              color: AppColors.gray900,
            ),
          ),
          SizedBox(width: context.w(16)),
          GestureDetector(
            onTap: onNextMonth,
            child: Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

