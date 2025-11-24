import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/candle_model.dart';

class VolumeChartV2 extends StatelessWidget {
  final List<CandleData> candles;

  const VolumeChartV2({
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

    final totalVolume = candles.fold<double>(0, (sum, c) => sum + c.volume);
    
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Vol: ${_formatVolume(totalVolume)}',
              style: AppFonts.c2.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: VolumePainter(
                candles: candles,
                maxVolume: _getMaxVolume(),
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxVolume() {
    if (candles.isEmpty) return 100;
    return candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(0);
    }
  }
}

class VolumePainter extends CustomPainter {
  final List<CandleData> candles;
  final double maxVolume;

  VolumePainter({
    required this.candles,
    required this.maxVolume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    // 캔들스틱 차트와 동일한 고정 너비와 간격
    final barWidth = 8.0; // CandlestickPainter와 동일한 너비
    final barSpacing = 12.0; // CandlestickPainter와 동일한 간격 (16 → 12로 수정!)
    
    // 차트 시작 위치 계산 (중앙 정렬)
    final totalWidth = candles.length * barSpacing;
    final startX = (size.width - totalWidth) / 2 + barWidth / 2;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = startX + i * barSpacing;
      
      // 볼륨을 Y 좌표로 변환
      final barHeight = (candle.volume / maxVolume) * size.height;
      final barY = size.height - barHeight;

      // 상승/하락에 따른 색상 결정
      final isPositive = candle.close >= candle.open;
      paint.color = isPositive ? AppColors.chartBlue : AppColors.chartRed;

      // 볼륨 바 그리기
      canvas.drawRect(
        Rect.fromLTWH(
          x - barWidth / 2,
          barY,
          barWidth,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VolumePainter oldDelegate) {
    return candles != oldDelegate.candles ||
           maxVolume != oldDelegate.maxVolume;
  }
}
