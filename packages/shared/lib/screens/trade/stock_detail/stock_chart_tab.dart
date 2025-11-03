import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/chart/candlestick_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/volume_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/rsi_indicators_v2.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/api/exchange_rate_api_service.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:qbit_services/websocket/crypto_market_websocket.dart';

class StockChartTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;
  final String? binanceSymbol; // 암호화폐 API 호출용
  final Function(String price, String change)? onPriceUpdate;
  final Function(String priceUSD, String priceKRW)? onPriceUpdateDetailed;

  const StockChartTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.binanceSymbol,
    this.onPriceUpdate,
    this.onPriceUpdateDetailed,
  });

  @override
  State<StockChartTab> createState() => _StockChartTabState();
}

class _StockChartTabState extends State<StockChartTab> {
  String _selectedInterval = '1h';
  CandleResponse? _candleData;
  bool _isLoading = false;
  String? _error;
  double? _exchangeRate;
  double? _currentRealTimePrice;
  CryptoMarketWebSocket? _marketWebSocket; // 실시간 시장가용 WebSocket

  final List<String> _intervals = ['30m', '1h', '4h', '1d'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _marketWebSocket?.disconnect();
    _marketWebSocket?.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (widget.assetClass != 'crypto') return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 환율 로드
      _exchangeRate = await ExchangeRateApiService.getUsdToKrwRate();
      
      // 실시간 시세 로드
      await _loadRealTimePrice();
      
      // 캔들 데이터 로드
      await _loadCandleData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadRealTimePrice() async {
    if (widget.assetClass != 'crypto') return;
    
    // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
    final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
    if (binanceSymbol.isEmpty) return;
    
    try {
      // WebSocket 연결하여 실시간 시장가 받기
      _marketWebSocket = CryptoMarketWebSocket();
      await _marketWebSocket!.connect(binanceSymbol);
      
      // WebSocket에서 실시간 가격 받기
      _marketWebSocket!.lastPriceStream.listen((price) {
        print('=== 실시간 가격 수신 ===');
        print('WebSocket에서 받은 가격: $price');
        print('현재 _currentRealTimePrice: $_currentRealTimePrice');
        print('=====================');
        
        if (mounted && price > 0) {
          setState(() {
            _currentRealTimePrice = price;
          });
          
          print('업데이트된 가격: $_currentRealTimePrice');
          print('포맷팅된 가격: ${_formatPriceValue(_currentRealTimePrice!)}');
          
          // 콜백으로 가격 정보 업데이트
          if (_currentRealTimePrice != null) {
            final priceStr = _formatPriceValue(_currentRealTimePrice!);
            final changeStr = _getPriceChange();
            widget.onPriceUpdate?.call(priceStr, changeStr);
          }
        }
      });
    } catch (e) {
      print('실시간 시세 WebSocket 연결 에러: $e');
      // WebSocket 실패 시 REST API로 폴백 (선택적)
      try {
        final quote = await StockApiService.getCryptoQuote(binanceSymbol);
        if (quote != null && mounted) {
          final price = quote['lastPrice'] ?? 
                       quote['currentPrice'] ?? 
                       quote['price'] ?? 
                       quote['close'];
          
          if (price != null) {
            final priceValue = (price is num) ? price.toDouble() : double.tryParse(price.toString());
            if (priceValue != null) {
              setState(() {
                _currentRealTimePrice = priceValue;
              });
            }
          }
        }
      } catch (e2) {
        print('REST API 폴백도 실패: $e2');
      }
    }
  }

  Future<void> _loadCandleData() async {
    if (widget.assetClass != 'crypto') return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 환율 로드 (암호화폐의 경우 USD를 KRW로 변환)
      _exchangeRate = await ExchangeRateApiService.getUsdToKrwRate();
      
      // 현재 시간과 시간 단위에 따라 조정된 기간 계산
      final now = DateTime.now();
      final int daysBack;
      
      switch (_selectedInterval) {
        case '30m':
        case '1h':
          daysBack = 30; // 30일치 데이터 (더 많은 데이터로 끊김 방지)
          break;
        case '4h':
          daysBack = 60; // 60일치 데이터
          break;
        case '1d':
          daysBack = 90; // 90일치 데이터
          break;
        default:
          daysBack = 30;
      }
      
      final startTime = now.subtract(Duration(days: daysBack));
      
      // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
      final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
      if (binanceSymbol.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'binanceSymbol이 필요합니다';
            _isLoading = false;
          });
        }
        return;
      }
      
      final candleData = await StockApiService.getCryptoCandles(
        binanceSymbol: binanceSymbol,
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
          final firstCandle = candleData!.candles.first;
          
          // 디버깅: 캔들 데이터 타임스탬프 확인
          print('=== 캔들 데이터 확인 ===');
          print('캔들 개수: ${candleData!.candles.length}');
          print('첫 캔들 timestamp: ${firstCandle.timestamp}');
          print('첫 캔들 시간: ${DateTime.fromMillisecondsSinceEpoch(firstCandle.timestamp)}');
          print('마지막 캔들 timestamp: ${latestCandle.timestamp}');
          print('마지막 캔들 시간: ${DateTime.fromMillisecondsSinceEpoch(latestCandle.timestamp)}');
          print('마지막 캔들 close: ${latestCandle.close}');
          print('======================');
          
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
    
    // 인터벌이 변경되면 가격 정보 업데이트
    if (mounted && _candleData != null && _candleData!.candles.isNotEmpty) {
      final latestCandle = _candleData!.candles.last;
      final price = _formatPrice(latestCandle.close);
      final change = _getPriceChange();
      widget.onPriceUpdate?.call(price, change);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 종목 정보 헤더
          _buildHeader(),
          
          // 헤더와 간격 선택 바 사이 여백
          SizedBox(height: context.h(20)),
          
          // 시간 간격 선택 바
          _buildIntervalSelector(),
          
          // 간격 선택 바 아래 얇은 가로선
          Container(
            height: 1,
            color: AppColors.gray100,
          ),
          
          // 가로선과 차트 사이 여백
          SizedBox(height: context.h(16)),
          
          // 차트 영역
          Expanded(
            child: _buildChartArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // 현재 가격과 등락률 계산
    final currentPrice = _getCurrentPrice();
    final priceChange = _getPriceChange();
    final priceChangeColor = _getPriceChangeColor();
    
    // 가격값 추출 (소수점 포함)
    final priceValue = currentPrice;
    
    return Container(
      height: 86,
      padding: EdgeInsets.fromLTRB(context.w(20), context.h(20), context.w(20), 0),
      child: Stack(
        children: [
          // 종목명 (위쪽)
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              widget.name.toUpperCase(),
              style: AppFonts.b1Semibold.copyWith(
                color: AppColors.gray900,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          // 가격과 등락률 (아래쪽)
          Positioned(
            left: 0,
            top: 29,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 가격
                Text(
                  priceValue,
                  style: AppFonts.b1Semibold.copyWith(
                    color: AppColors.gray900,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    height: 0.88,
                  ),
                ),
                SizedBox(width: context.w(12)),
                // 등락률
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 등락 아이콘 (작은 삼각형 또는 화살표)
                    Icon(
                      _isPriceUp() ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 8,
                      color: priceChangeColor,
                    ),
                    SizedBox(width: context.w(3)),
                    Text(
                      priceChange,
                      style: AppFonts.b2Regular.copyWith(
                        color: priceChangeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.23,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 이동/설정 아이콘 (오른쪽)
          Positioned(
            right: 0,
            top: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                    color: AppColors.gray300,
                ),
              ),
              SizedBox(width: context.w(8)),
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
                    color: AppColors.gray300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(36), vertical: 0),
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
          SizedBox(width: context.w(17)),
          
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
          SizedBox(width: context.w(17)),
          
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
          SizedBox(width: context.w(17)),
          
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
            SizedBox(height: context.h(16)),
            Text(
              '차트 데이터를 불러올 수 없습니다',
              style: AppFonts.b1Regular.copyWith(
                color: AppColors.gray600,
              ),
            ),
            SizedBox(height: context.h(8)),
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
            SizedBox(height: context.h(16)),
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
      realTimePrice: _currentRealTimePrice, // 실시간 시세 전달
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
    // 실시간 시세 우선 사용
    if (_currentRealTimePrice != null) {
      return _formatPriceValue(_currentRealTimePrice!);
    }
    
    // 없으면 캔들 데이터의 마지막 close 사용
    if (_candleData != null && _candleData!.candles.isNotEmpty) {
      final lastCandle = _candleData!.candles.last;
      return _formatPriceValue(lastCandle.close);
    }
    
    return '--';
  }

  String _formatPriceValue(double price) {
    if (widget.assetClass == 'crypto') {
      // 암호화폐: 소수점 2자리 + 쉼표 표시
      return _formatNumberWithComma(price);
    } else {
      // 주식: 정수로 표시하되 필요시 소수점
      if (price >= 1000) {
        return _formatNumberWithComma(price);
      } else if (price >= 1) {
        return price.toStringAsFixed(2);
      } else {
        return price.toStringAsFixed(6);
      }
    }
  }

  String _formatNumberWithComma(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // 천 단위 쉼표 추가
    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return '$formattedInteger.$decimalPart';
  }

  String _getPriceChange() {
    // 실시간 시세가 있으면 사용
    double? currentPrice;
    double? previousPrice;
    
    if (_currentRealTimePrice != null && _candleData != null && _candleData!.candles.isNotEmpty) {
      currentPrice = _currentRealTimePrice;
      previousPrice = _candleData!.candles[_candleData!.candles.length - 2].close;
    } else if (_candleData != null && _candleData!.candles.length >= 2) {
      final currentCandle = _candleData!.candles.last;
      final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
      currentPrice = currentCandle.close;
      previousPrice = previousCandle.close;
    }
    
    if (currentPrice == null || previousPrice == null || previousPrice == 0) {
      return '-- (0.00%)';
    }
    
    final change = currentPrice - previousPrice;
    final changePercent = (change / previousPrice) * 100;
    
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.abs().toStringAsFixed(2)} (${changePercent.abs().toStringAsFixed(2)}%)';
  }

  String _formatPrice(double price) {
    // 암호화폐의 경우 USD를 KRW로 변환
    if (widget.assetClass == 'crypto' && _exchangeRate != null) {
      final krwPrice = price * _exchangeRate!;
      return '${krwPrice.toStringAsFixed(2)}원';
    }
    
    // 주식의 경우 이미 KRW 단위
    if (price >= 1000) {
      return '${price.toStringAsFixed(2)}원';
    } else if (price >= 1) {
      return '${price.toStringAsFixed(4)}원';
    } else {
      return '${price.toStringAsFixed(6)}원';
    }
  }

  Color _getPriceChangeColor() {
    // 실시간 가격이 있으면 이전 캔들과 비교
    if (_currentRealTimePrice != null && _candleData != null && _candleData!.candles.isNotEmpty) {
      if (_candleData!.candles.length >= 2) {
        final previousPrice = _candleData!.candles[_candleData!.candles.length - 2].close;
        final change = _currentRealTimePrice! - previousPrice;
        return change >= 0 ? AppColors.profit : AppColors.loss;
      }
    }
    
    // 실시간 가격이 없으면 캔들 데이터로 비교
    if (_candleData == null || _candleData!.candles.length < 2) {
      return AppColors.gray400;
    }
    
    final currentCandle = _candleData!.candles.last;
    final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
    
    final change = currentCandle.close - previousCandle.close;
    return change >= 0 ? AppColors.profit : AppColors.loss;
  }

  bool _isPriceUp() {
    // 실시간 가격이 있으면 이전 캔들과 비교
    if (_currentRealTimePrice != null && _candleData != null && _candleData!.candles.isNotEmpty) {
      if (_candleData!.candles.length >= 2) {
        final previousPrice = _candleData!.candles[_candleData!.candles.length - 2].close;
        final change = _currentRealTimePrice! - previousPrice;
        return change >= 0;
      }
    }
    
    // 실시간 가격이 없으면 캔들 데이터로 비교
    if (_candleData == null || _candleData!.candles.length < 2) {
      return true;
    }
    
    final currentCandle = _candleData!.candles.last;
    final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
    
    final change = currentCandle.close - previousCandle.close;
    return change >= 0;
  }
}