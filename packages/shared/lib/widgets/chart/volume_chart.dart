import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';

class VolumeChart extends StatelessWidget {
  final List<CandleData> candles;

  const VolumeChart({
    super.key,
    required this.candles,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Center(
        child: Text(
          '볼륨 데이터가 없습니다',
          style: AppFonts.b1Regular.copyWith(
            color: AppColors.gray600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
      child: Column(
        children: [
          // 볼륨 차트 제목 (숨김)
          const SizedBox(height: 0),
          
          // 볼륨 바 차트
          Expanded(
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxVolume() * 1.1,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x.toInt();
                          if (index >= 0 && index < candles.length) {
                            final candle = candles[index];
                            return BarTooltipItem(
                              'Vol: ${_formatVolume(candle.volume)}',
                              AppFonts.b2Regular.copyWith(
                                color: Colors.white,
                              ),
                            );
                          }
                          return null;
                        },
                      ),
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
                          reservedSize: 30,
                          interval: candles.length > 20 ? candles.length / 10 : 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '',
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.gray600,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: _getMaxVolume() / 5,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatVolume(value),
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.gray600,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppColors.gray200,
                        width: 1,
                      ),
                    ),
                    barGroups: _getBarGroups(),
                  ),
                ),
                // 볼륨 텍스트
                Positioned(
                  left: 0,
                  top: 8,
                  child: Text(
                    'Vol: 112,177',
                    style: AppFonts.b2Regular.copyWith(
                      color: AppColors.gray600,
                      fontSize: 11,
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

  List<BarChartGroupData> _getBarGroups() {
    return candles.asMap().entries.map((entry) {
      final index = entry.key;
      final candle = entry.value;
      final isPositive = candle.close >= candle.open;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: candle.volume,
            color: isPositive ? AppColors.chartBlue : AppColors.chartRed,
            width: 2,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxVolume() {
    if (candles.isEmpty) return 100;
    return candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);
  }

  double _getTotalVolume() {
    if (candles.isEmpty) return 0;
    return candles.map((c) => c.volume).reduce((a, b) => a + b);
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }
}
