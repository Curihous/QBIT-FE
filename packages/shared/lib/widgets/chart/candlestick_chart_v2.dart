import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

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
          style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        final maxFit = _CandlestickPainter.maxCandlesForWidth(width);
        final visibleCandles = _selectVisibleCandles(maxFit);
        if (visibleCandles.isEmpty) {
          return const SizedBox.shrink();
        }

        final _PriceBounds bounds = _calculatePriceBounds(visibleCandles);

        return CustomPaint(
          size: Size(width, height),
          painter: _CandlestickPainter(
            candles: visibleCandles,
            interval: interval,
            currentPrice: realTimePrice,
            minPrice: bounds.min,
            maxPrice: bounds.max,
          ),
        );
      },
    );
  }

  List<CandleData> _selectVisibleCandles(int maxFit) {
    if (candles.isEmpty) return const [];
    final int maxVisible = math.max(1, maxFit);

    final int limit;
    switch (interval) {
      case '30m':
        limit = 40;
        break;
      case '1h':
        limit = 40;
        break;
      case '4h':
        limit = 40;
        break;
      default:
        limit = 80;
    }

    final target = math.min(limit, maxVisible);
    if (candles.length <= target) {
      return candles;
    }
    return candles.sublist(candles.length - target);
  }

  _PriceBounds _calculatePriceBounds(List<CandleData> data) {
    final highs = data.map((c) => c.high);
    final lows = data.map((c) => c.low);

    double max = highs.reduce(math.max);
    double min = lows.reduce(math.min);
    final range = max - min;

    if (range == 0) {
      final padding = _minRangeFor(max) / 2;
      max += padding;
      min -= padding;
    } else {
      final padding = range * 0.15;
      max += padding;
      min -= padding;
    }

    return _PriceBounds(min: min, max: max);
  }

  double _minRangeFor(double anchor) {
    final a = anchor.abs();
    if (a < 1) return 0.02;
    if (a < 100) return a * 0.01;
    if (a < 1000) return a * 0.005;
    return a * 0.003;
  }
}

class _CandlestickPainter extends CustomPainter {
  static const double _leftPadding = 16;
  static const double _rightPadding = 64;
  static const double _topPadding = 48;
  static const double _bottomPadding = 36;
  static const double _candleWidth = 6;
  static const double _candleSpacing = 3;

  static int maxCandlesForWidth(double width) {
    final usable = width - _leftPadding - _rightPadding;
    if (usable <= _candleWidth) {
      return 1;
    }
    final unit = _candleWidth + _candleSpacing;
    final count = (usable / unit).floor();
    return math.max(1, count);
  }

  final List<CandleData> candles;
  final String interval;
  final double? currentPrice;
  final double minPrice;
  final double maxPrice;

  const _CandlestickPainter({
    required this.candles,
    required this.interval,
    required this.currentPrice,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _topPadding - _bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    _drawGrid(canvas, size, chartWidth, chartHeight);
    _drawCandles(canvas, chartWidth, chartHeight);
    _drawXAxis(canvas, size, chartWidth);
    _drawCurrentPriceLine(canvas, size, chartWidth, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    const int labelCount = 5;
    final double priceStep = (maxPrice - minPrice) / (labelCount - 1);
    final Paint gridPaint = Paint()
      ..color = AppColors.gray100
      ..strokeWidth = 1;

    for (int i = 0; i < labelCount; i++) {
      final price = minPrice + priceStep * i;
      final y = _priceToY(price, chartHeight);

      canvas.drawLine(
        Offset(_leftPadding, y),
        Offset(_leftPadding + chartWidth, y),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatPrice(price),
          style: const TextStyle(fontSize: 10, color: AppColors.gray600),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }

  void _drawCandles(Canvas canvas, double chartWidth, double chartHeight) {
    final totalWidth = candles.length * _candleWidth + (candles.length - 1) * _candleSpacing;
    // 왼쪽부터 시작하도록 수정
    final double startX = _leftPadding + _candleWidth / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = startX + i * (_candleWidth + _candleSpacing);
      final highY = _priceToY(candle.high, chartHeight);
      final lowY = _priceToY(candle.low, chartHeight);
      final openY = _priceToY(candle.open, chartHeight);
      final closeY = _priceToY(candle.close, chartHeight);

      final bool bullish = candle.close >= candle.open;
      paint.color = bullish ? AppColors.profit : AppColors.loss;

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint..strokeWidth = 1);

      final rect = Rect.fromLTWH(
        x - _candleWidth / 2,
        math.min(openY, closeY),
        _candleWidth,
        (openY - closeY).abs().clamp(1.0, chartHeight),
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _drawXAxis(Canvas canvas, Size size, double chartWidth) {
    if (candles.length < 2) return;

    // 4h 간격일 때는 균등한 간격으로 라벨 배치 (다른 간격과 동일하게)
    if (interval == '4h') {
      const int labelCount = 6;
      final double step = (candles.length - 1) / (labelCount - 1);
      final double startX = _leftPadding + _candleWidth / 2;

      // 중복 날짜 제거를 위한 Set
      Set<String> seenDates = {};

      for (int i = 0; i < labelCount; i++) {
        final int index = (step * i).round().clamp(0, candles.length - 1);
        final candle = candles[index];
        final x = startX + index * (_candleWidth + _candleSpacing);
        final String label = _formatTime(candle.timestamp);

        // 중복 날짜 제거
        if (seenDates.contains(label)) continue;
        seenDates.add(label);

        final textPainter = TextPainter(
          text: TextSpan(text: label, style: const TextStyle(fontSize: 10, color: AppColors.gray600)),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        double textX = x - textPainter.width / 2;
        if (textX < _leftPadding) textX = _leftPadding;
        if (textX + textPainter.width > _leftPadding + chartWidth) {
          textX = _leftPadding + chartWidth - textPainter.width;
        }

        textPainter.paint(
          canvas,
          Offset(textX, size.height - _bottomPadding + (_bottomPadding - textPainter.height) / 2),
        );
      }
      return;
    }

    // 다른 간격은 기존 방식 사용
    const int labelCount = 6;
    final double step = (candles.length - 1) / (labelCount - 1);
    final double startX = _leftPadding + _candleWidth / 2;

    for (int i = 0; i < labelCount; i++) {
      final int index = (step * i).round().clamp(0, candles.length - 1);
      final candle = candles[index];
      final x = startX + index * (_candleWidth + _candleSpacing);
      final String label = _formatTime(candle.timestamp);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(fontSize: 10, color: AppColors.gray600)),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      double textX = x - textPainter.width / 2;
      if (textX < _leftPadding) textX = _leftPadding;
      if (textX + textPainter.width > _leftPadding + chartWidth) {
        textX = _leftPadding + chartWidth - textPainter.width;
      }

      textPainter.paint(
        canvas,
        Offset(textX, size.height - _bottomPadding + (_bottomPadding - textPainter.height) / 2),
      );
    }
  }

  void _drawCurrentPriceLine(Canvas canvas, Size size, double chartWidth, double chartHeight) {
    if (currentPrice == null) return;
    final y = _priceToY(currentPrice!, chartHeight).clamp(_topPadding, _topPadding + chartHeight);

    final Paint dashPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1;

    const double dash = 4;
    const double gap = 4;
    double start = _leftPadding;
    while (start < _leftPadding + chartWidth) {
      canvas.drawLine(Offset(start, y), Offset(math.min(start + dash, _leftPadding + chartWidth), y), dashPaint);
      start += dash + gap;
    }

    final priceText = _formatPrice(currentPrice!);
    final textPainter = TextPainter(
      text: TextSpan(text: priceText, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final double padding = 4;
    final double boxWidth = textPainter.width + padding * 2;
    final double boxHeight = textPainter.height + padding * 2;
    final double boxX = size.width - boxWidth - 8;
    final double boxY = (y - boxHeight / 2).clamp(_topPadding, _topPadding + chartHeight - boxHeight);

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
      const Radius.circular(4),
    );

    final Paint boxPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(rrect, boxPaint);
    textPainter.paint(canvas, Offset(boxX + padding, boxY + padding));
  }

  double _priceToY(double price, double chartHeight) {
    final double range = maxPrice - minPrice;
    if (range <= 0) return _topPadding + chartHeight / 2;
    final double ratio = (price - minPrice) / range;
    return _topPadding + chartHeight - ratio * chartHeight;
  }

  String _formatPrice(double value) {
    final double absValue = value.abs();
    if (absValue >= 1000) {
      return NumberFormat('#,##0').format(value);
    }
    if (absValue >= 1) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(4);
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    switch (interval) {
      case '4h':
        // 4h 간격은 날짜 형식으로 표시
        return DateFormat('MM/dd').format(date);
      case '1d':
      case '1w':
      case '1M':
        return DateFormat('MM/dd').format(date);
      default:
        return DateFormat('HH:mm').format(date);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.currentPrice != currentPrice ||
        oldDelegate.interval != interval;
  }
}

class _PriceBounds {
  final double min;
  final double max;

  const _PriceBounds({required this.min, required this.max});
}