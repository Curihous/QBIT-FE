import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:qbit_services/models/trade_cycle_report_model.dart';

class TradeReportChart extends StatelessWidget {
  final List<CandleData> candles;
  final List<TradePoint> tradePoints;
  final String interval;

  const TradeReportChart({
    super.key,
    required this.candles,
    required this.tradePoints,
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

    // 이동 평균선 계산 (20일 이동평균)
    final movingAverage = _calculateMovingAverage(candles, 20);
    
    // 차트 너비 계산 (캔들 개수에 따라 동적 조정, 최소 너비는 화면 너비)
    final chartWidth = (candles.length * 8.0).clamp(400.0, double.infinity);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 캔들스틱 차트 + 이동 평균선
              SizedBox(
                height: 270,
                child: Stack(
              children: [
                // 캔들스틱 차트
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxPrice(),
                    minY: _getMinPrice(),
                    barTouchData: BarTouchData(
                      enabled: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: _getPriceInterval(),
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                _formatPrice(value),
                                style: TextStyle(
                                  color: AppColors.gray600,
                                  fontSize: 10,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: _getPriceInterval(),
                      verticalInterval: _getXAxisInterval(),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.gray200.withOpacity(0.5),
                          strokeWidth: 0.5,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: AppColors.gray200.withOpacity(0.5),
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    barGroups: _getCandlestickBars(),
                  ),
                ),
                // 이동 평균선
                if (movingAverage.isNotEmpty)
                  LineChart(
                    LineChartData(
                      lineTouchData: const LineTouchData(enabled: false),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: movingAverage,
                          isCurved: true,
                          color: const Color(0xFF4DD4B8), // 민트색
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      minY: _getMinPrice(),
                      maxY: _getMaxPrice(),
                    ),
                  ),
                // 매수/매도 포인트 화살표
                CustomPaint(
                  painter: _TradePointsPainter(
                    tradePoints: tradePoints,
                    candles: candles,
                    minPrice: _getMinPrice(),
                    maxPrice: _getMaxPrice(),
                  ),
                  child: Container(),
                ),
                ],
              ),
              ),
              const SizedBox(height: 8),
              // 거래량 차트
              SizedBox(
                height: 90,
                child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxVolume(),
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: _getXAxisInterval(),
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.gray200.withOpacity(0.5),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                barGroups: _getVolumeBars(),
              ),
            ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _calculateMovingAverage(List<CandleData> candles, int period) {
    if (candles.length < period) return [];
    
    final List<FlSpot> ma = [];
    for (int i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += candles[j].close;
      }
      final avg = sum / period;
      ma.add(FlSpot(i.toDouble(), avg));
    }
    return ma;
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
            fromY: candle.open < candle.close ? candle.open : candle.close,
            toY: candle.open < candle.close ? candle.close : candle.open,
            color: isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), // 파란색/빨간색
            width: 6,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(1),
              bottom: Radius.circular(1),
            ),
          ),
          // 고가 선
          BarChartRodData(
            fromY: candle.high,
            toY: candle.high,
            color: isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
            width: 1,
          ),
          // 저가 선
          BarChartRodData(
            fromY: candle.low,
            toY: candle.low,
            color: isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
            width: 1,
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _getVolumeBars() {
    return candles.asMap().entries.map((entry) {
      final index = entry.key;
      final candle = entry.value;
      final isPositive = candle.close >= candle.open;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: candle.volume,
            color: isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
            width: 4,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMinPrice() {
    if (candles.isEmpty) return 0;
    final minPrice = candles.map((c) => [c.open, c.high, c.low, c.close]).expand((x) => x).reduce((a, b) => a < b ? a : b);
    return minPrice * 0.98;
  }

  double _getMaxPrice() {
    if (candles.isEmpty) return 100;
    final maxPrice = candles.map((c) => [c.open, c.high, c.low, c.close]).expand((x) => x).reduce((a, b) => a > b ? a : b);
    return maxPrice * 1.02;
  }

  double _getMaxVolume() {
    if (candles.isEmpty) return 100;
    final maxVolume = candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);
    return maxVolume * 1.1;
  }

  double _getPriceInterval() {
    final priceRange = _getMaxPrice() - _getMinPrice();
    if (priceRange <= 0) return 1;
    
    if (priceRange < 1) return 0.1;
    if (priceRange < 10) return 1;
    if (priceRange < 100) return 10;
    if (priceRange < 1000) return 100;
    return 1000;
  }

  double _getXAxisInterval() {
    if (candles.isEmpty) return 1;
    
    final dataCount = candles.length;
    if (dataCount <= 10) return 2;
    if (dataCount <= 20) return 4;
    if (dataCount <= 50) return dataCount / 4;
    if (dataCount <= 100) return dataCount / 5;
    if (dataCount <= 200) return dataCount / 6;
    return dataCount / 8;
  }

  String _formatPrice(double price) {
    if (price < 1) return price.toStringAsFixed(4);
    if (price < 10) return price.toStringAsFixed(3);
    if (price < 100) return price.toStringAsFixed(2);
    if (price < 1000) return price.toStringAsFixed(1);
    return price.toStringAsFixed(0);
  }

  String _formatTime(int index) {
    if (index >= 0 && index < candles.length) {
      final timestamp = candles[index].timestamp;
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
}

class _TradePointsPainter extends CustomPainter {
  final List<TradePoint> tradePoints;
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;

  _TradePointsPainter({
    required this.tradePoints,
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    if (priceRange <= 0) return;
    
    // 차트 영역 계산 (좌우 여백 50, 상하 여백 고려)
    final chartWidth = size.width - 100; // 좌측 50 + 우측 50
    final chartHeight = size.height;
    final candleSpacing = chartWidth / candles.length;
    final leftPadding = 50.0;

    for (final tradePoint in tradePoints) {
      // tradePoint의 timestamp를 밀리초에서 초로 변환
      final tradeTimestampSeconds = tradePoint.timestamp ~/ 1000;
      
      // 가장 가까운 캔들 찾기
      int? candleIndex;
      int minDiff = 999999999;
      for (int i = 0; i < candles.length; i++) {
        final diff = (candles[i].timestamp - tradeTimestampSeconds).abs();
        if (diff < minDiff) {
          minDiff = diff;
          candleIndex = i;
        }
      }
      
      if (candleIndex == null || minDiff > 1800) continue; // 30분 이내

      // X 위치 계산 (캔들 중앙)
      final x = leftPadding + candleIndex * candleSpacing + candleSpacing / 2;
      
      // Y 위치 계산 (가격에 따라)
      final normalizedPrice = (tradePoint.price - minPrice) / priceRange;
      final priceY = chartHeight - (normalizedPrice * chartHeight);
      
      // 화살표 그리기
      final paint = Paint()
        ..color = tradePoint.side.toUpperCase() == 'BUY' 
            ? const Color(0xFF3B82F6) // 파란색 상향
            : const Color(0xFFEF4444) // 빨간색 하향
        ..style = PaintingStyle.fill;

      final arrowSize = 14.0;
      final path = Path();
      
      if (tradePoint.side.toUpperCase() == 'BUY') {
        // 상향 화살표 (위쪽)
        path.moveTo(x, priceY - arrowSize);
        path.lineTo(x - arrowSize / 2, priceY - arrowSize / 3);
        path.lineTo(x + arrowSize / 2, priceY - arrowSize / 3);
        path.close();
      } else {
        // 하향 화살표 (아래쪽)
        path.moveTo(x, priceY + arrowSize);
        path.lineTo(x - arrowSize / 2, priceY + arrowSize / 3);
        path.lineTo(x + arrowSize / 2, priceY + arrowSize / 3);
        path.close();
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

