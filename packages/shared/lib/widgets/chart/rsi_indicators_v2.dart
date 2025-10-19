import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';

class RSIIndicatorsV2 extends StatelessWidget {
  final List<CandleData> candles;

  const RSIIndicatorsV2({
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
          const SizedBox(height: 0),
          Expanded(
            child: CustomPaint(
              painter: RSIPainter(
                candles: candles,
                rsi6: rsi6,
                rsi12: rsi12,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
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

class RSIPainter extends CustomPainter {
  final List<CandleData> candles;
  final List<double> rsi6;
  final List<double> rsi12;

  RSIPainter({
    required this.candles,
    required this.rsi6,
    required this.rsi12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 캔들스틱 차트와 동일한 고정 간격
    final pointSpacing = 16.0; // 고정 간격
    
    // 차트 시작 위치 계산 (중앙 정렬)
    final totalWidth = candles.length * pointSpacing;
    final startX = (size.width - totalWidth) / 2;

    // RSI(6) 라인 그리기
    if (rsi6.isNotEmpty) {
      paint.color = AppColors.primary;
      _drawRSILine(canvas, paint, rsi6, startX, pointSpacing, size.height);
    }

    // RSI(12) 라인 그리기
    if (rsi12.isNotEmpty) {
      paint.color = AppColors.secondaryMain;
      _drawRSILine(canvas, paint, rsi12, startX, pointSpacing, size.height);
    }

    // RSI 레벨 라인 그리기 (80, 50, 20)
    paint.color = AppColors.gray200;
    paint.strokeWidth = 1.0;
    
    // 80 레벨
    final y80 = size.height * 0.2; // 80% 위치
    canvas.drawLine(
      Offset(0, y80),
      Offset(size.width, y80),
      paint,
    );
    
    // 50 레벨
    final y50 = size.height * 0.5; // 50% 위치
    canvas.drawLine(
      Offset(0, y50),
      Offset(size.width, y50),
      paint,
    );
    
    // 20 레벨
    final y20 = size.height * 0.8; // 20% 위치
    canvas.drawLine(
      Offset(0, y20),
      Offset(size.width, y20),
      paint,
    );
  }

  void _drawRSILine(Canvas canvas, Paint paint, List<double> rsiValues, 
                    double startX, double spacing, double height) {
    if (rsiValues.isEmpty) return;

    final path = Path();
    bool isFirstPoint = true;

    for (int i = 0; i < rsiValues.length; i++) {
      final x = startX + i * spacing;
      final y = height - (rsiValues[i] / 100) * height; // RSI는 0-100 범위

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RSIPainter oldDelegate) {
    return candles != oldDelegate.candles ||
           rsi6 != oldDelegate.rsi6 ||
           rsi12 != oldDelegate.rsi12;
  }
}
