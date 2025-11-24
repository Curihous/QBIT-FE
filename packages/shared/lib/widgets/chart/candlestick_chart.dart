import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';

class CandlestickChart extends StatelessWidget {
  final List<CandleData> candles;
  final String interval;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Center(
        child: Text(
          '차트 데이터가 없습니다',
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
          // 차트 제목 (숨김)
          const SizedBox(height: 0),
          
          // 캔들스틱 차트 (BarChart로 구현)
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxPrice(),
                minY: _getMinPrice(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(12),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      if (index >= 0 && index < candles.length) {
                        final candle = candles[index];
                        return BarTooltipItem(
                          '${_formatDateTime(candle.timestamp)}\n'
                          'Open: ${_formatPrice(candle.open)}\n'
                          'High: ${_formatPrice(candle.high)}\n'
                          'Low: ${_formatPrice(candle.low)}\n'
                          'Close: ${_formatPrice(candle.close)}\n'
                          'Vol: ${_formatVolume(candle.volume)}',
                          AppFonts.b2Regular.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: _getPriceInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatPrice(value),
                          style: AppFonts.b2Regular.copyWith(
                            color: AppColors.gray600,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getTimeInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatTime(value),
                          style: AppFonts.b2Regular.copyWith(
                            color: AppColors.gray600,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _getPriceInterval(),
                  verticalInterval: _getTimeInterval(),
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
                barGroups: _getCandlestickBars(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getCandlestickBars() {
    return candles.asMap().entries.map((entry) {
      final index = entry.key;
      final candle = entry.value;
      final isPositive = candle.close >= candle.open;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          // 캔들 몸통 (시가-종가)
          BarChartRodData(
            fromY: candle.open,
            toY: candle.close,
            color: isPositive ? AppColors.chartBlue : AppColors.chartRed,
            width: 4,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
              bottom: Radius.circular(2),
            ),
          ),
          // 고가 선
          BarChartRodData(
            fromY: candle.high,
            toY: candle.high,
            color: isPositive ? AppColors.chartBlue : AppColors.chartRed,
            width: 1,
          ),
          // 저가 선
          BarChartRodData(
            fromY: candle.low,
            toY: candle.low,
            color: isPositive ? AppColors.chartBlue : AppColors.chartRed,
            width: 1,
          ),
        ],
      );
    }).toList();
  }

  double _getMinPrice() {
    if (candles.isEmpty) return 0;
    final minPrice = candles.map((c) => [c.open, c.high, c.low, c.close]).expand((x) => x).reduce((a, b) => a < b ? a : b);
    return minPrice * 0.98; // 2% 여유
  }

  double _getMaxPrice() {
    if (candles.isEmpty) return 100;
    final maxPrice = candles.map((c) => [c.open, c.high, c.low, c.close]).expand((x) => x).reduce((a, b) => a > b ? a : b);
    return maxPrice * 1.02; // 2% 여유
  }

  double _getPriceInterval() {
    final priceRange = _getMaxPrice() - _getMinPrice();
    if (priceRange <= 0) return 1;
    
    // 가격 범위에 따라 적절한 간격 설정
    if (priceRange < 1) return 0.1;
    if (priceRange < 10) return 1;
    if (priceRange < 100) return 10;
    if (priceRange < 1000) return 100;
    return 1000;
  }

  double _getTimeInterval() {
    final dataCount = candles.length;
    if (dataCount <= 10) return 1;
    if (dataCount <= 50) return 5;
    if (dataCount <= 100) return 10;
    return dataCount / 10;
  }

  String _formatPrice(double price) {
    if (price < 1) return price.toStringAsFixed(4);
    if (price < 10) return price.toStringAsFixed(3);
    if (price < 100) return price.toStringAsFixed(2);
    if (price < 1000) return price.toStringAsFixed(1);
    return price.toStringAsFixed(0);
  }

  String _formatTime(double index) {
    final intIndex = index.toInt();
    if (intIndex >= 0 && intIndex < candles.length) {
      final timestamp = candles[intIndex].timestamp;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      
      switch (interval) {
        case '1m':
        case '5m':
        case '15m':
        case '30m':
          return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        case '1h':
        case '4h':
          return '${date.month}/${date.day}';
        case '1d':
        case '1w':
        case '1M':
          return '${date.month}/${date.day}';
        default:
          return '${date.month}/${date.day}';
      }
    }
    return '';
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
