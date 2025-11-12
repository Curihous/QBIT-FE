import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:intl/intl.dart';

class CandlestickChartV2 extends StatelessWidget {
  final List<CandleData> candles;
  final String interval;
  final double? realTimePrice;

  const CandlestickChartV2({
    super.key,
    required this.candles,
    required this.interval,
    this.realTimePrice,
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
                candles: _getRecentCandles(), // 최근 캔들만 표시 (사이즈 조절)
                maxPrice: _getMaxPrice(),
                minPrice: _getMinPrice(),
                currentPrice: realTimePrice ?? candles.last.close, // 실시간 시세 우선 사용
                interval: interval,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  /// 가격 크기에 따른 최소 표시 범위 (너무 납작해지는 것 방지)
  double _minRangeFor(double anchor) {
    final a = anchor.abs();
    if (a < 1) return 0.02;          // 2센트 수준
    if (a < 100) return a * 0.005;   // ±0.5%
    return a * 0.003;                // ±0.3%
  }

  double _getMaxPrice() {
    if (candles.isEmpty) return 0;
    
    final recentCandles = _getRecentCandles();
    if (recentCandles.isEmpty) return 0;
    
    // --- realTimePrice 관련 로직 모두 제거 ---
    // 1. 캔들 데이터 기준으로 최대/최소값 계산
    double max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    
    // 2. 캔들 데이터의 기본 범위(range) 계산
    final range = max - min;
    
    // 3. 차트가 너무 납작해지는 것을 방지하기 위한 최소 범위
    final minRange = _minRangeFor(max); // (기존에 만드신 함수 활용)
    
    // 4. 실제 범위와 최소 범위 중 더 큰 값을 사용
    final effectiveRange = math.max(range, minRange);
    
    // 5. 캔들 데이터의 중심점 계산
    final center = (max + min) / 2;
    
    // 6. 패딩 적용 (중심점 + 유효범위/2 + 패딩)
    // (패딩 비율은 effectiveRange 기준으로 적용)
    final padding = _getPaddingRatio(); 
    
    return center + (effectiveRange / 2) + (effectiveRange * padding);
  }

  double _getMinPrice() {
    if (candles.isEmpty) return 0;
    
    final recentCandles = _getRecentCandles();
    if (recentCandles.isEmpty) return 0;
    
    // --- realTimePrice 관련 로직 모두 제거 ---
    // 1. 캔들 데이터 기준으로 최대/최소값 계산
    final max = recentCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double min = recentCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    
    // 2. 캔들 데이터의 기본 범위(range) 계산
    final range = max - min;
    
    // 3. 차트가 너무 납작해지는 것을 방지하기 위한 최소 범위
    final minRange = _minRangeFor(min); // (기존에 만드신 함수 활용)
    
    // 4. 실제 범위와 최소 범위 중 더 큰 값을 사용
    final effectiveRange = math.max(range, minRange);
    
    // 5. 캔들 데이터의 중심점 계산
    final center = (max + min) / 2;
    
    // 6. 패딩 적용 (중심점 - 유효범위/2 - 패딩)
    // (패딩 비율은 effectiveRange 기준으로 적용)
    final padding = _getPaddingRatio();
    
    return center - (effectiveRange / 2) - (effectiveRange * padding);
  }
  
  List<CandleData> _getRecentCandles() {
    // 시간 단위별 최근 캔들 개수 (auto-scale 효과)
    final count = _getRecentCandleCount();
    final startIndex = candles.length > count ? candles.length - count : 0;
    return candles.sublist(startIndex);
  }
  
  int _getRecentCandleCount() {
    // 화면 크기에 맞춰 동적으로 계산
    // 일반적으로 화면 너비 360px 기준으로 계산
    switch (interval) {
      case '1m':
      case '5m':
        return 30; // 짧은 간격
      case '15m':
        return 40;
      case '30m':
        return 48; // 48개 = 약 24시간 (더 많은 캔들로 정확도 향상)
      case '1h':
        return 48; // 48개 = 약 2일 (더 많은 캔들로 정확도 향상)
      case '4h':
        return 21; // 21개 = 약 3.5일
      case '1d':
        return 30; // 30개 = 약 1개월
      case '1w':
        return candles.length; // 전체 데이터
      case '1M':
        return candles.length; // 전체 데이터
      default:
        return 50; // 기본값
    }
  }
  
  bool _isShortTimeframe() {
    return ['1m', '5m', '15m', '30m', '1h'].contains(interval);
  }
  
  /// Y축 패딩 비율 (20%)
  double _getPaddingRatio() => 0.20;
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
    final rightPadding = 70.0; // Y축 라벨 공간 증가
    final leftPadding = 16.0;
    final topPadding = 60.0; // 120 → 60으로 줄임 (시간 메뉴와 차트 사이 여백 최적화)
    final bottomPadding = 0.0; // X축 라벨 숨김
    
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

    // 시간 간격에 따라 캔들 너비와 간격 조정
    final bool isShortInterval = interval == '30m' || interval == '1h';
    final candleWidth = isShortInterval ? 4.0 : 6.0; // 30m, 1h는 더 좁게
    final candleSpacing = isShortInterval ? 2.0 : 3.0; // 30m, 1h는 간격 더 좁게
    
    // 차트의 총 폭 계산 (마지막 캔들 뒤 간격은 제외)
    final totalCandleWidth = (candles.length * candleWidth) + ((candles.length - 1) * candleSpacing);

    // 화면보다 좁으면 수평 중앙 정렬, 넓으면 마지막 캔들이 우측에 오도록 정렬
    double startX;
    if (totalCandleWidth <= chartWidth) {
      final leftover = chartWidth - totalCandleWidth;
      startX = leftPadding + leftover / 2 + candleWidth / 2; // 중앙 정렬
    } else {
      startX = leftPadding + chartWidth - (candleWidth / 2) - (candles.length - 1) * (candleWidth + candleSpacing); // 우측 정렬
      // 화면 밖으로 벗어나지 않도록 최소값 보정
      final minStartX = leftPadding + candleWidth / 2;
      if (startX < minStartX) startX = minStartX;
    }

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = startX + i * (candleWidth + candleSpacing);
      
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

    // TODO: X축 라벨 그리기 (시간) - 일단 숨김 (나중에 캔들 터치로 상세 정보 표시로 대체)
    // _drawXAxisLabels(canvas, size, leftPadding, topPadding, chartWidth, actualChartHeight, startX, candleSpacing, bottomPadding);
  }

  void _drawGridAndYAxis(Canvas canvas, Size size, double leftPadding, double topPadding, double chartWidth, double chartHeight) {
    final gridPaint = Paint()
      ..color = AppColors.gray100
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Y축 라벨 개수와 간격 조정
    final labelCount = 5;
    final priceStep = (maxPrice - minPrice) / (labelCount - 1);
    
    for (int i = 0; i < labelCount; i++) {
      final rawPrice = minPrice + (priceStep * i);
      // 라벨은 실제 값 기반으로 표시 (과도한 반올림으로 동일 값 반복되는 문제 방지)
      final price = rawPrice;
      final y = _priceToY(price, chartHeight, topPadding);
      
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
    // 현재가 선은 항상 표시 (범위 밖이어도)
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
    final labelCount = interval == '30m' || interval == '15m' ? 8 : 
                       interval == '1h' ? 7 :
                       interval == '4h' ? 7 : 
                       interval == '1d' ? 6 : 5; // 더 많은 라벨 표시
    
    for (int i = 0; i < labelCount; i++) {
      final candleIndex = (i * (candles.length - 1) / (labelCount - 1)).round();
      final candle = candles[candleIndex];
      final x = startX + candleIndex * (6.0 + 3.0); // 실제 캔들 위치에 맞춰 표시 (candleWidth 6.0 + candleSpacing 3.0)
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

  double _roundToNiceValue(double value) {
    if (value == 0) return 0;
    
    // 값의 크기에 따라 적절한 단위 결정
    final absValue = value.abs();
    final magnitude = absValue < 1 
        ? 0 
        : (math.log(absValue) / math.ln10).floor();
    final magnitudeValue = math.pow(10, magnitude).toDouble();
    
    // 값의 첫 번째 자리수 추출
    final normalizedValue = value / magnitudeValue;
    
    // 깔끔한 숫자로 반올림 (1, 2, 5, 10 단위)
    double niceValue;
    if (normalizedValue <= 1) {
      niceValue = 1;
    } else if (normalizedValue <= 2) {
      niceValue = 2;
    } else if (normalizedValue <= 5) {
      niceValue = 5;
    } else {
      niceValue = 10;
    }
    
    return niceValue * magnitudeValue;
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