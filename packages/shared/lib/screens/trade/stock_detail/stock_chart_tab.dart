import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/chart/candlestick_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/volume_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/rsi_indicators_v2.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/candle_model.dart';

class StockChartTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;
  final Function(String price, String change)? onPriceUpdate;

  const StockChartTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.onPriceUpdate,
  });

  @override
  State<StockChartTab> createState() => _StockChartTabState();
}

class _StockChartTabState extends State<StockChartTab> {
  String _selectedInterval = '1h';
  CandleResponse? _candleData;
  bool _isLoading = false;
  String? _error;

  final List<String> _intervals = ['30m', '1h', '4h', '1d'];

  @override
  void initState() {
    super.initState();
    _loadCandleData();
  }

  Future<void> _loadCandleData() async {
    if (widget.assetClass != 'crypto') return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 현재 시간과 7일 전 시간 계산
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7));
      
      final candleData = await StockApiService.getCryptoCandles(
        symbol: widget.symbol,
        interval: _selectedInterval,
        startTime: startTime.millisecondsSinceEpoch,
        endTime: now.millisecondsSinceEpoch,
      );

      if (mounted) {
        setState(() {
          _candleData = candleData;
          _isLoading = false;
        });
        
        // 가격 정보 업데이트
        if (candleData != null && candleData!.candles.isNotEmpty) {
          final latestCandle = candleData!.candles.last;
          final price = _formatPrice(latestCandle.close);
          final change = _getPriceChange();
          widget.onPriceUpdate?.call(price, change);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onIntervalChanged(String interval) {
    setState(() {
      _selectedInterval = interval;
    });
    _loadCandleData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 상단 여백
          const SizedBox(height: 16),
          
          // 종목 정보 헤더
          _buildHeader(),
          
          // 헤더와 간격 선택 바 사이 여백
          const SizedBox(height: 20),
          
          // 시간 간격 선택 바
          _buildIntervalSelector(),
          
          // 간격 선택 바 아래 얇은 가로선
          Container(
            height: 1,
            color: AppColors.gray100,
          ),
          
          // 가로선과 차트 사이 여백
          const SizedBox(height: 16),
          
          // 차트 영역
          Expanded(
            child: _buildChartArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          // 종목명
          Expanded(
            child: Text(
              widget.name,
              style: AppFonts.b1Semibold.copyWith(
                color: AppColors.gray900,
                fontSize: 18,
              ),
            ),
          ),
          // 아이콘 
          Row(
            children: [
              // 화살표 아이콘 (차트 확대, 축소)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gray100,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.open_with,
                  size: 20,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(width: 8),
              // 톱니바퀴 아이콘
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gray100,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  size: 20,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 30m
          Container(
            width: 50,
            height: 34,
            child: GestureDetector(
              onTap: () => _onIntervalChanged('30m'),
              child: Center(
                child: Text(
                  '30m',
                  textAlign: TextAlign.center,
                  style: AppFonts.b1Regular.copyWith(
                    color: _selectedInterval == '30m' 
                        ? AppColors.primary 
                        : AppColors.gray900,
                    fontSize: 16,
                    fontWeight: _selectedInterval == '30m' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          
          // 1h
          Container(
            width: 50,
            height: 34,
            child: GestureDetector(
              onTap: () => _onIntervalChanged('1h'),
              child: Center(
                child: Text(
                  '1h',
                  textAlign: TextAlign.center,
                  style: AppFonts.b1Regular.copyWith(
                    color: _selectedInterval == '1h' 
                        ? AppColors.primary 
                        : AppColors.gray900,
                    fontSize: 16,
                    fontWeight: _selectedInterval == '1h' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          
          // 4h
          Container(
            width: 50,
            height: 34,
            child: GestureDetector(
              onTap: () => _onIntervalChanged('4h'),
              child: Center(
                child: Text(
                  '4h',
                  textAlign: TextAlign.center,
                  style: AppFonts.b1Regular.copyWith(
                    color: _selectedInterval == '4h' 
                        ? AppColors.primary 
                        : AppColors.gray900,
                    fontSize: 16,
                    fontWeight: _selectedInterval == '4h' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          
          // 1d
          Container(
            width: 50,
            height: 34,
            child: GestureDetector(
              onTap: () => _onIntervalChanged('1d'),
              child: Center(
                child: Text(
                  '1d',
                  textAlign: TextAlign.center,
                  style: AppFonts.b1Regular.copyWith(
                    color: _selectedInterval == '1d' 
                        ? AppColors.primary 
                        : AppColors.gray900,
                    fontSize: 16,
                    fontWeight: _selectedInterval == '1d' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          
          // 기타 옵션
          GestureDetector(
            onTap: () {
              // 기타 옵션 처리
            },
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '기타 ',
                    style: AppFonts.b1Regular.copyWith(
                      color: AppColors.gray900,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: '▾',
                    style: AppFonts.b1Bold.copyWith(
                      color: AppColors.gray900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              '차트 데이터를 불러올 수 없습니다',
              style: AppFonts.b1Regular.copyWith(
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppFonts.b2Regular.copyWith(
                color: AppColors.gray400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_candleData == null || _candleData!.candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              '차트 데이터가 없습니다',
              style: AppFonts.b1Regular.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          // 캔들스틱 차트 영역
          Expanded(
            flex: 5, // 3 → 5로 증가 (더 크게)
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: _buildCandlestickChart(),
            ),
          ),
          
          const SizedBox(height: 0),
          
          // 볼륨 차트 영역
          SizedBox(
            height: 80, // 고정 높이로 변경 (Expanded → SizedBox)
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: _buildVolumeChart(),
            ),
          ),
          
          const SizedBox(height: 0),
          
          // RSI 지표 영역
          SizedBox(
            height: 60, // 고정 높이로 변경 (Expanded → SizedBox)
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: _buildRSIIndicators(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandlestickChart() {
    return CandlestickChartV2(
      candles: _candleData!.candles,
      interval: _selectedInterval,
    );
  }

  Widget _buildVolumeChart() {
    return VolumeChartV2(
      candles: _candleData!.candles,
    );
  }

  Widget _buildRSIIndicators() {
    return RSIIndicatorsV2(
      candles: _candleData!.candles,
    );
  }

  String _getCurrentPrice() {
    if (_candleData == null || _candleData!.candles.isEmpty) {
      return '--원';
    }
    final lastCandle = _candleData!.candles.last;
    return '${lastCandle.close.toStringAsFixed(0)}원';
  }

  String _getPriceChange() {
    if (_candleData == null || _candleData!.candles.length < 2) {
      return '--%';
    }
    
    final currentCandle = _candleData!.candles.last;
    final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
    
    final change = currentCandle.close - previousCandle.close;
    final changePercent = (change / previousCandle.close) * 100;
    
    final sign = change >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  String _formatPrice(double price) {
    // 암호화폐는 소수점까지 정확하게 표시
    if (price >= 1000) {
      return '${price.toStringAsFixed(2)}원';
    } else if (price >= 1) {
      return '${price.toStringAsFixed(4)}원';
    } else {
      return '${price.toStringAsFixed(6)}원';
    }
  }

  Color _getPriceChangeColor() {
    if (_candleData == null || _candleData!.candles.length < 2) {
      return AppColors.gray400;
    }
    
    final currentCandle = _candleData!.candles.last;
    final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
    
    final change = currentCandle.close - previousCandle.close;
    return change >= 0 ? AppColors.profit : AppColors.loss;
  }
}