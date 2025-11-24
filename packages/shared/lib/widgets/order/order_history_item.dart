import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 주문 내역 개별 항목 카드 위젯
class OrderHistoryItem extends StatelessWidget {
  final String orderDateText;
  final String symbol;
  final String quantityAndPriceText;
  final String statusText;
  final bool isBuy;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDeleteTap;

  const OrderHistoryItem({
    super.key,
    required this.orderDateText,
    required this.symbol,
    required this.quantityAndPriceText,
    required this.statusText,
    required this.isBuy,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    // 매수(RED), 매도(BLUE) - 프로젝트 공통 규칙에 맞춰 색상 매핑
    final sideColor = isBuy ? AppColors.chartRed : AppColors.chartBlue;

    return Container(
      // 컴포넌트 간 간격
      margin: EdgeInsets.only(bottom: context.h(16)),
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      height: context.h(83.367),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 주문 요청일 (YY.MM.DD)
          Text(
            orderDateText,
            style: AppFonts.c1.copyWith(
              color: AppColors.gray600,
              fontSize: 13,
              height: 1.23,
            ),
          ),
          SizedBox(height: context.h(4)),

          // 본문 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 로고 이미지
              Container(
                width: context.w(42),
                height: context.h(42),
                decoration: const ShapeDecoration(
                  color: AppColors.secondaryBG,
                  shape: OvalBorder(),
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    'assets/icons/stock_search_screen/company-logo-basic.svg',
                    width: context.w(42),
                    height: context.h(42),
                  ),
                ),
              ),

              SizedBox(width: context.w(12)),

              // 심볼 / 수량·가격
              Expanded(
                child: GestureDetector(
                  onLongPress: onLongPress,
                  onTap: onTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 좌측: 심볼 + 수량·가격 (2줄)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 심볼
                            Text(
                              symbol,
                              style: AppFonts.b1Semibold.copyWith(
                                color: AppColors.gray900,
                                height: 1.25,
                              ),
                            ),
                            SizedBox(height: context.h(4)),
                            // 수량·가격
                            Text(
                              quantityAndPriceText,
                              style: AppFonts.c1.copyWith(
                                color: sideColor,
                                fontSize: 13,
                                height: 1.23,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: context.w(8)),

                      // 우측: 주문 상태
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            statusText,
                            style: AppFonts.c1.copyWith(
                              color: AppColors.gray600,
                              fontSize: 13,
                              height: 1.23,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


