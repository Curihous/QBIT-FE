import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/api/report_api_service.dart';
import 'package:qbit_services/models/trade_report_model.dart';

class TradeReportScreen extends StatefulWidget {
  final int tradeCycleId;

  const TradeReportScreen({
    super.key,
    required this.tradeCycleId,
  });

  @override
  State<TradeReportScreen> createState() => _TradeReportScreenState();
}

class _TradeReportScreenState extends State<TradeReportScreen> {
  bool _isLoading = true;
  TradeReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await ReportApiService.getTradeReport(widget.tradeCycleId);
      if (!mounted) return;

      setState(() {
        _report = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '리포트를 불러오지 못했습니다.\n다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '매매 리포트',
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null || _report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? '리포트를 불러오지 못했습니다.',
              style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadReport,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final report = _report!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 요약
          Text(
            '전체 평가',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          Text(
            report.overallEvaluation,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),

          const SizedBox(height: 24),

          // 시장 맥락
          Text(
            '시장 상황',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          Text(
            report.marketContext,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),

          const SizedBox(height: 24),

          // 매수 분석
          Text(
            '매수 타이밍 분석',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          _buildIndicatorSection('RSI', report.buyRsi),
          const SizedBox(height: 8),
          _buildIndicatorSection('MACD', report.buyMacd),
          const SizedBox(height: 12),
          Text(
            report.buyEvaluation,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Text(
            report.buyImprovement,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),

          const SizedBox(height: 24),

          // 매도 분석
          Text(
            '매도 타이밍 분석',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          _buildIndicatorSection('RSI', report.sellRsi),
          const SizedBox(height: 8),
          _buildIndicatorSection('MACD', report.sellMacd),
          const SizedBox(height: 12),
          Text(
            report.sellEvaluation,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Text(
            report.sellImprovement,
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),

          const SizedBox(height: 24),

          // 학습 카드 추천
          if (report.learningCards.isNotEmpty) ...[
            Text(
              '추천 학습 카드',
              style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
            ),
            const SizedBox(height: 12),
            Column(
              children: report.learningCards.map((card) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray30,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.description,
                        style: AppFonts.c1.copyWith(color: AppColors.gray600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorSection(String label, TradeReportIndicator indicator) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray30,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ${indicator.value.toStringAsFixed(2)}',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 4),
          Text(
            indicator.analysis,
            style: AppFonts.c1.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
