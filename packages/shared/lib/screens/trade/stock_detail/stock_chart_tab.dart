import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';

class StockChartTab extends StatefulWidget {
  final String symbol;
  final String name;

  const StockChartTab({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<StockChartTab> createState() => _StockChartTabState();
}

class _StockChartTabState extends State<StockChartTab> {
  StockModel? _stockDetail;
  bool _isLoading = true;
  String? _error;
  int _selectedTimeframeIndex = 1; // 0: 30m, 1: 1h, 2: 4h, 3: 1d, 4: 기타

  @override
  void initState() {
    super.initState();
    _loadStockDetail();
  }

  Future<void> _loadStockDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stockDetail = await StockApiService.getStockDetail(widget.symbol);
      
      if (mounted) {
        if (stockDetail != null) {
          setState(() {
            _stockDetail = stockDetail;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = '종목 정보를 불러올 수 없습니다';
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '오류가 발생했습니다: $error';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppFonts.b1Semibold.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStockDetail,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 주식명 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _stockDetail?.name ?? widget.name,
                        style: AppFonts.t2Bold.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                          height: 1.20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 이동 아이콘
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(
                        Icons.open_with,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 설정 아이콘
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // 시간 선택 섹션
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeOption('30m', 0),
                _buildTimeOption('1h', 1),
                _buildTimeOption('4h', 2),
                _buildTimeOption('1d', 3),
                _buildTimeOption('기타 ▾', 4),
              ],
            ),
          ),
          
          // 차트 영역
          Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                '차트 영역\n(구현 예정)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gray600,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String text, int index) {
    final isSelected = _selectedTimeframeIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeframeIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 1.40,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              width: 20,
              height: 2,
              color: AppColors.gray900,
            ),
        ],
      ),
    );
  }
}

