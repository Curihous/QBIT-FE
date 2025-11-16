import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 주문내역 거래 사이클 탭 아이템 위젯
class TradeCycleItem extends StatelessWidget {
  final String dateRangeText;
  final Widget leading;
  final String symbol;
  final String profitLossText;
  final Color profitLossColor;
  final VoidCallback onReportTap;

  const TradeCycleItem({
    super.key,
    required this.dateRangeText,
    required this.leading,
    required this.symbol,
    required this.profitLossText,
    required this.profitLossColor,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날짜 범위
          Padding(
            padding: EdgeInsets.only(left: context.w(16), bottom: context.h(2)),
            child: Text(
              dateRangeText,
              style: AppFonts.c1.copyWith(
                color: AppColors.gray600,
                fontSize: 13,
                height: 1.23,
              ),
            ),
          ),

          // 메인 컨텐츠 영역
          Container(
            width: double.infinity,
            height: context.h(65),
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 회사 로고 
                Container(
                  width: context.w(44),
                  height: context.h(44),
                  decoration: const ShapeDecoration(
                    color: AppColors.secondaryBG,
                    shape: OvalBorder(),
                  ),
                  child: Center(child: leading),
                ),

                SizedBox(width: context.w(14)),

                // 심볼명과 손익률/금액
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        symbol,
                        style: AppFonts.b1Semibold.copyWith(
                          color: AppColors.gray900,
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        profitLossText,
                        style: AppFonts.c1.copyWith(
                          color: profitLossColor,
                          fontSize: 13,
                          height: 1.23,
                        ),
                      ),
                    ],
                  ),
                ),

                // 리포트 아이콘 (항상 우측 끝에 붙도록 배치)
                GestureDetector(
                  onTap: onReportTap,
                  child: SizedBox(
                    width: context.w(32),
                    height: context.h(32),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SvgPicture.asset(
                        'assets/icons/trade/order_history_screen/report.svg',
                        width: context.w(24),
                        height: context.h(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


