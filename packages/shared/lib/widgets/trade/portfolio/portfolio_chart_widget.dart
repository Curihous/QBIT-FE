import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_shared/models/portfolio_history.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

// 데모용 포트폴리오 차트 위젯
class PortfolioChartWidget extends StatelessWidget {
  final List<PortfolioChartPoint> chartPoints;
  final double height;

  const PortfolioChartWidget({
    super.key,
    required this.chartPoints,
    this.height = 125,
  });

  @override
  Widget build(BuildContext context) {
    if (chartPoints.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray300, width: 1),
        ),
        child: const Center(
          child: Text('데이터가 없습니다'),
        ),
      );
    }

    // Y축 범위 계산 (타이트하게)
    final equityValues = chartPoints.map((e) => e.equity).toList();
    final minEquity = equityValues.reduce((a, b) => a < b ? a : b);
    final maxEquity = equityValues.reduce((a, b) => a > b ? a : b);
    
    // 약간의 여백 추가
    // minEquity == maxEquity인 경우를 처리하여 0 범위 방지
    double yAxisPadding;
    if (maxEquity == minEquity) {
      // 동일한 값일 때 최소 범위 보장 (값의 1% 또는 최소 1.0)
      yAxisPadding = (minEquity * 0.01).abs();
      if (yAxisPadding < 1.0) {
        yAxisPadding = 1.0;
      }
    } else {
      yAxisPadding = (maxEquity - minEquity) * 0.1;
    }
    final yMin = minEquity - yAxisPadding;
    final yMax = maxEquity + yAxisPadding;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              // horizontalInterval이 0이 되지 않도록 최소값 보장
              horizontalInterval: () {
                final range = yMax - yMin;
                final calculatedInterval = range / 4;
                // 최소 간격 보장 (0.01 또는 범위의 1%)
                final minInterval = range > 0 ? (range * 0.01).abs() : 0.01;
                return calculatedInterval > minInterval ? calculatedInterval : minInterval;
              }(),
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppColors.gray100,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: AppColors.gray100,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 18,
                  interval: 3, // 3개 간격으로 표시 (6:30, 9:30, 12:30)
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value.toInt() >= 0 && value.toInt() < chartPoints.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          chartPoints[value.toInt()].label,
                          style: AppFonts.c2.copyWith(color: AppColors.gray600),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (chartPoints.length - 1).toDouble(),
            minY: yMin,
            maxY: yMax,
            lineBarsData: [
              LineChartBarData(
                spots: chartPoints.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.equity);
                }).toList(),
                isCurved: true, // 부드러운 곡선
                color: const Color(0xFF00C9A7), // 지정된 색상
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false), // 포인트 없애기
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF00C9A7).withOpacity(0.1), // 연한 그라디언트
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF00C9A7).withOpacity(0.3),
                      const Color(0xFF00C9A7).withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final point = chartPoints[touchedSpot.x.toInt()];
                    return LineTooltipItem(
                      '${point.label}\n\$${point.equity.toStringAsFixed(2)}',
                      AppFonts.c2.copyWith(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
