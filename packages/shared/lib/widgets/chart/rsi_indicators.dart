import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';

class RSIIndicators extends StatelessWidget {
  final List<CandleData> candles;

  const RSIIndicators({
    super.key,
    required this.candles,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Center(
        child: Text(
          'RSI 데이터가 없습니다',
          style: AppFonts.b1Regular.copyWith(
            color: AppColors.gray600,
          ),
        ),
      );
    }

    final rsi6 = _calculateRSI(candles, 6);
    final rsi12 = _calculateRSI(candles, 12);

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
      child: Column(
        children: [
          // RSI 제목과 현재 값 (숨김)
          const SizedBox(height: 0),
          
          // RSI 차트
          Expanded(
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 10,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.gray200,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: AppColors.gray200,
                          strokeWidth: 1,
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
                          reservedSize: 40,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
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
                    minX: 0,
                    maxX: candles.length.toDouble() - 1,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      // RSI(6) 라인
                      LineChartBarData(
                        spots: _getRSISpots(rsi6),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                      // RSI(12) 라인
                      LineChartBarData(
                        spots: _getRSISpots(rsi12),
                        isCurved: true,
                        color: AppColors.secondaryMain,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            if (index >= 0 && index < candles.length) {
                              final rsi6Value = index < rsi6.length ? rsi6[index] : 0;
                              final rsi12Value = index < rsi12.length ? rsi12[index] : 0;
                              return LineTooltipItem(
                                'RSI(6): ${rsi6Value.toStringAsFixed(2)}\nRSI(12): ${rsi12Value.toStringAsFixed(2)}',
                                AppFonts.b2Regular.copyWith(
                                  color: Colors.white,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                // RSI 텍스트
                Positioned(
                  left: 0,
                  top: 8,
                  child: Row(
                    children: [
                      Text(
                        'RSI(6): 4.15',
                        style: AppFonts.b2Regular.copyWith(
                          color: AppColors.gray600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'RSI(12): 12.505',
                        style: AppFonts.b2Regular.copyWith(
                          color: AppColors.gray600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // RSI 레벨 표시
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRSILevel('과매수', 80, AppColors.loss),
              _buildRSILevel('중립', 50, AppColors.gray600),
              _buildRSILevel('과매도', 20, AppColors.profit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRSILevel(String label, double level, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label ($level)',
        style: AppFonts.b2Regular.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  List<FlSpot> _getRSISpots(List<double> rsiValues) {
    return rsiValues.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  List<double> _calculateRSI(List<CandleData> candles, int period) {
    if (candles.length < period + 1) return [];

    List<double> gains = [];
    List<double> losses = [];

    // 가격 변화 계산
    for (int i = 1; i < candles.length; i++) {
      final change = candles[i].close - candles[i - 1].close;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    List<double> rsi = [];
    
    // 초기 평균 계산
    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    for (int i = period; i < gains.length; i++) {
      // 지수 이동 평균 사용
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;

      if (avgLoss == 0) {
        rsi.add(100);
      } else {
        final rs = avgGain / avgLoss;
        final rsiValue = 100 - (100 / (1 + rs));
        rsi.add(rsiValue);
      }
    }

    return rsi;
  }
}
