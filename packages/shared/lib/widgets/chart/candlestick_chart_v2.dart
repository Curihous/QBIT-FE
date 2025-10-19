import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:intl/intl.dart';

class CandlestickChartV2 extends StatelessWidget {
  final List<CandleData> candles;
  final String interval;

  const CandlestickChartV2({
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
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      child: Column(
        children: [
          const SizedBox(height: 0),
          Expanded(
            child: CustomPaint(
              painter: CandlestickPainter(
                candles: _getRecentCandles(), // 전체 캔들 → 최근 캔들로 변경!
                maxPrice: _getMaxPrice(),
                minPrice: _getMinPrice(),
                currentPrice: candles.last.close,
                interval: interval,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxPrice() {
    if (candles.isEmpty) return 0;
    
    // 30m, 1h 차트는 현재가 기준으로 동적 범위 계산
    if (interval == '30m' || interval == '1h') {
      final recentCandles = _getRecentCandles();
      final max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final range = max - min;
      final padding = range * 0.1; // 10% 패딩
      return max + padding;
    }
    
    // 짧은 시간대는 최근 캔들들만 기준으로 auto-scale (enableAutoScaleY: true 효과)
    if (_isShortTimeframe()) {
      final recentCandles = _getRecentCandles();
      final max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final range = max - min;
      final padding = _getPaddingRatio();
      return max + (range * padding);
    }
    
    // 긴 시간대는 전체 캔들 기준
    final max = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final min = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range = max - min;
    final padding = _getPaddingRatio();
    return max + (range * padding);
  }

  double _getMinPrice() {
    if (candles.isEmpty) return 0;
    
    // 30m, 1h 차트는 현재가 기준으로 동적 범위 계산
    if (interval == '30m' || interval == '1h') {
      final recentCandles = _getRecentCandles();
      final max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final range = max - min;
      final padding = range * 0.1; // 10% 패딩
      return min - padding;
    }
    
    // 짧은 시간대는 최근 캔들들만 기준으로 auto-scale (enableAutoScaleY: true 효과)
    if (_isShortTimeframe()) {
      final recentCandles = _getRecentCandles();
      final max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final range = max - min;
      final padding = _getPaddingRatio();
      return min - (range * padding);
    }
    
    // 긴 시간대는 전체 캔들 기준
    final max = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final min = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final range = max - min;
    final padding = _getPaddingRatio();
    return min - (range * padding);
  }
  
  List<CandleData> _getRecentCandles() {
    // 시간 단위별 최근 캔들 개수 (auto-scale 효과)
    final count = _getRecentCandleCount();
    final startIndex = candles.length > count ? candles.length - count : 0;
    return candles.sublist(startIndex);
  }
  
  int _getRecentCandleCount() {
    switch (interval) {
      case '1m':
      case '5m':
        return 25; // 20 → 25로 증가 (더 풍부하게!)
      case '15m':
        return 25; // 30 → 25로 조정 (15분 차트 최적화)
      case '30m':
        return 20; // 30 → 20으로 조정 (30분 차트 최적화)
      case '1h':
        return 24; // 50 → 24로 조정 (하루치 데이터)
      case '4h':
        return 30; // 60 → 30으로 조정 (5일치 데이터)
      case '1d':
        return 30; // 그대로 유지
      case '1w':
        return candles.length; // 전체 데이터
      case '1M':
        return candles.length; // 전체 데이터
      default:
        return candles.length; // 전체
    }
  }
  
  bool _isShortTimeframe() {
    return ['1m', '5m', '15m', '30m', '1h'].contains(interval);
  }
  
  double _getPaddingRatio() {
    // 시간 단위에 따라 Y축 패딩 비율 조정 (요구사항 반영)
    switch (interval) {
      case '1m':
      case '5m':
      case '15m':
      case '30m':
      case '1h':
        return 0.10; // 10% 패딩 (봉 주변 5~10% 여백)
      case '4h':
        return 0.10; // 10% 패딩
      case '1d':
        return 0.15; // 15% 패딩
      case '1w':
      case '1M':
        return 0.15; // 15% 패딩 (전체 데이터 기준)
      default:
        return 0.10;
    }
  }
}

class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double maxPrice;
  final double minPrice;
  final double currentPrice;
  final String interval;

  CandlestickPainter({
    required this.candles,
    required this.maxPrice,
    required this.minPrice,
    required this.currentPrice,
    required this.interval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Y축 라벨을 위한 공간 확보
    final rightPadding = 60.0; // Y축 라벨 공간
    final leftPadding = 16.0;
    final topPadding = 60.0; // 120 → 60으로 줄임 (시간 메뉴와 차트 사이 여백 최적화)
    final bottomPadding = 30.0; // X축 라벨 공간
    
    final chartWidth = size.width - leftPadding - rightPadding;
    // 수정: 강제로 최소 높이를 보장하던 로직 제거
    final chartHeight = size.height - topPadding - bottomPadding;
    
    // CustomPaint는 Expanded 안에 있으므로, 주어진 size.height를 최대한 활용해야 합니다.
    // minChartHeight 로직을 제거하여 레이아웃 침범을 방지합니다.
    final actualChartHeight = chartHeight; // <--- 이 부분이 수정되었습니다.

    // **참고: chartWidth나 actualChartHeight가 0 이하일 경우 예외 처리 (선택 사항)**
    if (chartWidth <= 0 || actualChartHeight <= 0) return;

    // 1. 그리드 라인 및 Y축 라벨 그리기
    _drawGridAndYAxis(canvas, size, leftPadding, topPadding, chartWidth, actualChartHeight);

    // 2. 캔들스틱 그리기
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 고정된 캔들 너비와 간격으로 일관성 있는 차트 모양
    final candleWidth = 8.0; // 고정 너비
    final candleSpacing = 12.0; // 6 → 12로 적절하게 증가 (캔들 구분 가능!)
    
    // 차트 시작 위치 계산 (중앙 정렬)
    final totalWidth = candles.length * candleSpacing;
    final startX = leftPadding + (chartWidth - totalWidth) / 2 + candleWidth / 2;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = startX + i * candleSpacing;
      
      // 가격을 Y 좌표로 변환
      final highY = _priceToY(candle.high, actualChartHeight, topPadding);
      final lowY = _priceToY(candle.low, actualChartHeight, topPadding);
      final openY = _priceToY(candle.open, actualChartHeight, topPadding);
      final closeY = _priceToY(candle.close, actualChartHeight, topPadding);

      // 상승/하락에 따른 색상 결정
      final isBullish = candle.close >= candle.open;
      paint.color = isBullish ? AppColors.profit : AppColors.loss;

      // 윅 (고가-저가 선)
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        paint,
      );

      // 캔들 몸통
      final bodyTop = isBullish ? closeY : openY;
      final bodyBottom = isBullish ? openY : closeY;
      final bodyHeight = (bodyTop - bodyBottom).abs();
      
      if (bodyHeight > 0) {
        paint.style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            x - candleWidth / 2,
            bodyTop,
            candleWidth,
            bodyHeight,
          ),
          paint,
        );
        paint.style = PaintingStyle.stroke;
      }
    }

    // 3. 현재가 표시선 그리기
    _drawCurrentPriceLine(canvas, size, leftPadding, topPadding, chartWidth, actualChartHeight);

    // 4. X축 라벨 그리기 (시간)
    _drawXAxisLabels(canvas, size, leftPadding, topPadding, chartWidth, actualChartHeight, startX, candleSpacing, bottomPadding);
  }

  void _drawGridAndYAxis(Canvas canvas, Size size, double leftPadding, double topPadding, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppColors.gray100
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 5개의 가격 레벨 (균등 분할)
    final priceStep = (maxPrice - minPrice) / 4;
    
    for (int i = 0; i <= 4; i++) {
      final price = minPrice + (priceStep * i);
      final y = topPadding + chartHeight - (chartHeight * i / 4);
      
      // 그리드 라인
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
      
      // Y축 라벨 (우측)
      final textSpan = TextSpan(
        text: _formatPrice(price),
        style: TextStyle(
          color: AppColors.gray600,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding + chartWidth + 8, y - textPainter.height / 2),
      );
    }
  }

  void _drawCurrentPriceLine(Canvas canvas, Size size, double leftPadding, double topPadding, double chartWidth, double chartHeight) {
    final currentY = _priceToY(currentPrice, chartHeight, topPadding);
    
    // 민트색 점선
    final dashedPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // 점선 그리기
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    double startX = leftPadding;
    
    while (startX < leftPadding + chartWidth) {
      canvas.drawLine(
        Offset(startX, currentY),
        Offset(startX + dashWidth, currentY),
        dashedPaint,
      );
      startX += dashWidth + dashSpace;
    }
    
    // 가격 박스 (우측)
    final priceText = _formatPrice(currentPrice);
    final textSpan = TextSpan(
      text: priceText,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    
    final boxPadding = 4.0;
    final boxWidth = textPainter.width + boxPadding * 2;
    final boxHeight = textPainter.height + boxPadding * 2;
    final boxX = leftPadding + chartWidth + 4;
    final boxY = currentY - boxHeight / 2;
    
    // 박스 배경
    final boxPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        Radius.circular(4),
      ),
      boxPaint,
    );
    
    // 텍스트
    textPainter.paint(
      canvas,
      Offset(boxX + boxPadding, boxY + boxPadding),
    );
  }

  void _drawXAxisLabels(Canvas canvas, Size size, double leftPadding, double topPadding, double chartWidth, double chartHeight, double startX, double candleSpacing, double bottomPadding) {
    if (candles.isEmpty) return;

    // 차트 전체 폭에 균등하게 분산된 라벨 표시
    final labelCount = interval == '30m' || interval == '15m' ? 5 : 3; // 30m/15m는 5개, 나머지는 3개
    final step = chartWidth / (labelCount - 1);
    
    for (int i = 0; i < labelCount; i++) {
      final x = leftPadding + (i * step);
      final candleIndex = (i * (candles.length - 1) / (labelCount - 1)).round();
      final candle = candles[candleIndex];
      final timeText = _formatTime(candle.timestamp);
      
      final textSpan = TextSpan(
        text: timeText,
        style: TextStyle(
          color: AppColors.gray600,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      // 시작은 왼쪽 정렬, 끝은 우측 정렬, 중간은 중앙 정렬
      double textX;
      if (i == 0) {
        textX = x; // 왼쪽 정렬
      } else if (i == labelCount - 1) {
        textX = x - textPainter.width; // 우측 정렬
      } else {
        textX = x - textPainter.width / 2; // 중앙 정렬
      }
      
      textPainter.paint(
        canvas,
        Offset(textX, size.height - bottomPadding / 2 - textPainter.height / 2), // 차트 하단 패딩 영역 중앙에 위치
      );
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return NumberFormat('#,##0').format(price);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(4);
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    if (interval == '1d' || interval == '1w' || interval == '1M') {
      return DateFormat('MM/dd').format(date);
    } else if (interval == '30m' || interval == '15m') {
      // 30m, 15m 차트는 분 단위로 표시
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('HH:mm').format(date);
    }
  }

  double _priceToY(double price, double height, double topPadding) {
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return topPadding + height / 2;
    return topPadding + height - ((price - minPrice) / priceRange) * height;
  }

  @override
  bool shouldRepaint(CandlestickPainter oldDelegate) {
    return candles != oldDelegate.candles ||
           maxPrice != oldDelegate.maxPrice ||
           minPrice != oldDelegate.minPrice ||
           currentPrice != oldDelegate.currentPrice;
  }
}