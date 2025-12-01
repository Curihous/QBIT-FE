import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 월별 요약 카드 위젯
class MonthSummaryCard extends StatelessWidget {
  final int totalTrades;
  final double profitRate;
  final double cumulativeProfit;

  const MonthSummaryCard({
    super.key,
    required this.totalTrades,
    required this.profitRate,
    required this.cumulativeProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: context.w(16),
        right: context.w(16),
        top: context.h(12),
        bottom: context.h(12),
      ),
      width: context.w(360),
      height: context.h(62),
      decoration: BoxDecoration(
        color: AppColors.secondaryBG,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondaryMain,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 총 거래
          Expanded(
            child: _buildStatColumn(
              context,
              '총 거래',
              '$totalTrades회',
              AppColors.gray900,
            ),
          ),
          // 구분선
          Container(
            width: 1,
            height: context.h(30),
            color: AppColors.secondaryMain,
          ),
          // 수익률
          Expanded(
            child: _buildStatColumn(
              context,
              '수익률',
              '${profitRate >= 0 ? '+' : ''} ${profitRate.toStringAsFixed(1)}%',
              profitRate >= 0 ? AppColors.chartRed : AppColors.chartBlue,
            ),
          ),
          // 구분선
          Container(
            width: 1,
            height: context.h(30),
            color: AppColors.secondaryMain,
          ),
          // 누적 손익
          Expanded(
            child: _buildStatColumn(
              context,
              '누적 손익',
              '${cumulativeProfit >= 0 ? '+' : ''} \$${cumulativeProfit.toStringAsFixed(0)}',
              cumulativeProfit >= 0 ? AppColors.chartRed : AppColors.chartBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppFonts.c1.copyWith(
            color: AppColors.gray600,
          ),
        ),
        Text(
          value,
          style: AppFonts.b1Semibold.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

