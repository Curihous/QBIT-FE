import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qbit_services/models/portfolio_overview_model.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 포트폴리오 오버뷰 그래프 위젯
/// 터치 시 해당 시점의 자산 가치를 상단에 표시
class PortfolioOverviewChart extends StatefulWidget {
  final List<HistoryPoint> history; // 자산 변동 이력 데이터
  final double? selectedEquity; // 선택된 시점의 자산 가치
  final int? selectedTimestamp; // 선택된 시점의 타임스탬프
  final Function(double?, int?)? onTouch; // 터치 이벤트 콜백

  const PortfolioOverviewChart({
    super.key,
    required this.history,
    this.selectedEquity,
    this.selectedTimestamp,
    this.onTouch,
  });

  @override
  State<PortfolioOverviewChart> createState() => _PortfolioOverviewChartState();
}

class _PortfolioOverviewChartState extends State<PortfolioOverviewChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return _buildEmptyState();
    }

    final yRange = _calculateYRange();
    final spots = _buildSpots();

    return _buildChart(yRange, spots);
  }

  /// 데이터가 없을 때 표시할 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300, width: 1),
      ),
      child: Center(
        child: Text(
          '데이터가 없습니다',
          style: AppFonts.b2Regular.copyWith(color: AppColors.gray600),
        ),
      ),
    );
  }

  /// Y축 범위 계산 
  ({double min, double max}) _calculateYRange() {
    final equityValues = widget.history.map((e) => e.equity).toList();
    final minEquity = equityValues.reduce((a, b) => a < b ? a : b);
    final maxEquity = equityValues.reduce((a, b) => a > b ? a : b);
    
    final yAxisPadding = (maxEquity - minEquity) * 0.1;
    final yMin = (minEquity - yAxisPadding).clamp(0.0, double.infinity);
    final yMax = maxEquity + yAxisPadding;
    
    return (min: yMin, max: yMax);
  }

  /// 차트 데이터 포인트 생성 (타임스탬프, 자산)
  List<FlSpot> _buildSpots() {
    return widget.history.map((point) {
      return FlSpot(point.timestamp.toDouble(), point.equity);
    }).toList();
  }

  /// 차트 위젯 빌드
  Widget _buildChart(({double min, double max}) yRange, List<FlSpot> spots) {

    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(16),
          context.w(16),
          context.h(8),
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              show: false,
            ),
            minX: widget.history.first.timestamp.toDouble(),
            maxX: widget.history.last.timestamp.toDouble(),
            minY: yRange.min,
            maxY: yRange.max,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 1.0],
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchSpotThreshold: 20,
              getTouchLineStart: (data, index) => double.infinity, // 터치 세로선 숨기기
              getTouchLineEnd: (data, index) => double.infinity, // 터치 세로선 숨기기
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 4,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tooltipMargin: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.spotIndex;
                    
                    if (index >= 0 && index < widget.history.length) {
                      final point = widget.history[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(point.timestamp);
                      final month = date.month;
                      final day = date.day;
                      final dateText = '$month월 $day일';
                      
                      return LineTooltipItem(
                        dateText,
                        AppFonts.c2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    
                    return LineTooltipItem('', const TextStyle(fontSize: 0));
                  }).toList();
                },
              ),
              touchCallback: _handleTouch,
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  /// 차트 터치 이벤트 처리 (선택된 시점의 자산 가치 전달)
  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
      _restoreLatestValue();
      return;
    }
    
    final spot = response.lineBarSpots!.first;
    final index = spot.spotIndex;
    
    if (index >= 0 && index < widget.history.length) {
      final point = widget.history[index];
      widget.onTouch?.call(point.equity, point.timestamp);
    }
  }

  /// 터치 해제 시 최신 자산 가치로 복원
  void _restoreLatestValue() {
    if (widget.history.isNotEmpty) {
      final latestPoint = widget.history.last;
      widget.onTouch?.call(latestPoint.equity, latestPoint.timestamp);
    }
  }
}

