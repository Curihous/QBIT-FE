import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/chart/candlestick_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/volume_chart_v2.dart';
import 'package:qbit_shared/widgets/chart/rsi_indicators_v2.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/api/exchange_rate_api_service.dart';
import 'package:qbit_services/models/candle_model.dart';
import 'package:qbit_services/websocket/crypto_market_websocket.dart';
import 'package:qbit_services/websocket/us_stock_market_websocket.dart';

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
  UsStockMarketWebSocket? _usStockWebSocket;
  StreamSubscription<PolygonEvent>? _usStockStreamSubscription;

  final List<String> _intervals = ['30m', '1h', '4h', '1d'];

  @override
  void initState() {
    super.initState();
    if (_isCrypto) {
      _loadCryptoData();
    } else if (_isUsStock) {
      _loadUsStockInitialData();
    }
  }

  @override
  void dispose() {
    _marketWebSocket?.disconnect();
    _marketWebSocket?.dispose();
    _usStockStreamSubscription?.cancel();
    // Singleton이므로 close/dispose 하지 않음
    // 구독 해제는 하지 않음 (다른 탭에서 사용 중일 수 있음)
    // 실제로는 구독 카운트를 관리하거나, 모든 화면이 닫힐 때만 해제해야 함
    // _usStockWebSocket?.close();
    // _usStockWebSocket?.dispose();
    super.dispose();
  }

  bool get _isCrypto => widget.assetClass == 'crypto';
  bool get _isUsStock => widget.assetClass == 'us_equity' || widget.assetClass == 'stock';
  
  Future<void> _loadCryptoData() async {
    if (!_isCrypto) return;

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

  Future<void> _loadUsStockInitialData() async {
    try {
      _exchangeRate ??= await ExchangeRateApiService.getUsdToKrwRate();
    } catch (e) {
      debugPrint('환율 조회 실패(미국 주식): $e');
    }

    await _loadUsStockCandles();
    await _connectUsStockRealtime();
  }

  Future<void> _loadUsStockCandles() async {
    if (!_isUsStock) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now().toUtc();
      final config = _resolveUsIntervalConfig(_selectedInterval);
      final fromDate = now.subtract(config.lookback);

      final response = await StockApiService.getUsStockCandles(
        ticker: widget.symbol,
        multiplier: config.multiplier,
        timespan: config.timespan,
        from: fromDate,
        to: now,
        adjusted: true,
      );

      if (!mounted) return;

      setState(() {
        _candleData = response;
        _isLoading = false;
      });

      if (response != null && response.candles.isNotEmpty) {
        _handleRealtimePrice(response.candles.last.close);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  _UsIntervalConfig _resolveUsIntervalConfig(String interval) {
    switch (interval) {
      case '30m':
        return const _UsIntervalConfig(
          multiplier: 30,
          timespan: 'minute',
          lookback: Duration(days: 5),
        );
      case '1h':
        return const _UsIntervalConfig(
          multiplier: 1,
          timespan: 'hour',
          lookback: Duration(days: 14),
        );
      case '4h':
        return const _UsIntervalConfig(
          multiplier: 4,
          timespan: 'hour',
          lookback: Duration(days: 60),
        );
      case '1d':
        return const _UsIntervalConfig(
          multiplier: 1,
          timespan: 'day',
          lookback: Duration(days: 365),
        );
      default:
        return const _UsIntervalConfig(
          multiplier: 1,
          timespan: 'day',
          lookback: Duration(days: 180),
        );
    }
  }

  Future<void> _connectUsStockRealtime() async {
    if (!_isUsStock) return;
    // Singleton 사용 시 _usStockWebSocket 체크 로직 변경
    // if (_usStockWebSocket != null) return; 

    final apiKey = dotenv.env['POLYGON_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Polygon API key is missing. Cannot connect to US stock websocket.');
      return;
    }

    if (_exchangeRate == null) {
      try {
        _exchangeRate = await ExchangeRateApiService.getUsdToKrwRate();
      } catch (e) {
        debugPrint('환율 조회 실패: $e');
      }
    }

    final symbol = widget.symbol.trim();
    if (symbol.isEmpty) return;

    // Singleton 인스턴스 사용
    final ws = UsStockMarketWebSocket.instance;
    _usStockWebSocket = ws;

    try {
      // A (Aggregate Second) 채널 사용 - 더 자주 업데이트
      await ws.connect(apiKey: apiKey, initialSymbols: []);
      ws.subscribe([symbol], trade: false, aggregateMinute: false, aggregateSecond: true, quote: false);
      
      _usStockStreamSubscription = ws.stream.listen((event) {
        // 내 심볼에 대한 이벤트인지 확인
        if (event.symbol != symbol) return;

        double? price;
        if (event is PolygonTrade) {
          price = event.price;
        } else if (event is PolygonAggregateSecond) {
          price = event.close;
        } else if (event is PolygonAggregateMinute) {
          price = event.close;
        }

        if (price != null) {
          _handleRealtimePrice(price);
        }
      });
    } catch (e) {
      debugPrint('미국 주식 실시간 시세 WebSocket 연결 실패: $e');
    }
  }

  void _handleRealtimePrice(double price) {
    if (!mounted) return;

    setState(() {
      _currentRealTimePrice = price;
    });

    final priceStr = _formatPriceValue(price);
    final changeStr = _getPriceChange();
    widget.onPriceUpdate?.call(priceStr, changeStr);

    final usdLabel = _formatUsdPriceLabel(price);
    final krwLabel = _formatKrwPriceLabel(price);
    widget.onPriceUpdateDetailed?.call(usdLabel, krwLabel);
  }
  
  Future<void> _loadRealTimePrice() async {
    if (!_isCrypto) return;
    
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
      
      // 제미나이 의사코드 방식: startTime/endTime 없이 limit=500으로 최신 데이터만 요청
      final now = DateTime.now();
      print('=== API 요청 (제미나이 방식) ===');
      print('현재 시간: $now');
      print('인터벌: $_selectedInterval');
      print('limit: 500 (최신 500개)');
      print('startTime/endTime: 없음 (API가 최신 데이터 반환)');
      print('============================');
      
      final candleData = await StockApiService.getCryptoCandles(
        binanceSymbol: binanceSymbol,
        interval: _selectedInterval,
        startTime: null, // 제거: API가 최신 데이터 반환
        endTime: null,   // 제거: API가 최신 데이터 반환
        limit: 500,      // 최신 500개 요청
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
          
          // 디버깅: API 응답 데이터 확인
          final latestCandleTime = DateTime.fromMillisecondsSinceEpoch(latestCandle.timestamp);
          final firstCandleTime = DateTime.fromMillisecondsSinceEpoch(firstCandle.timestamp);
          final timeDiff = now.difference(latestCandleTime);
          
          print('=== API 응답 데이터 확인 ===');
          print('API: /stocks/crypto/candle/$binanceSymbol');
          print('인터벌: $_selectedInterval');
          print('전체 캔들 개수 (allCandles): ${candleData!.candles.length}');
          print('첫 캔들 시간: $firstCandleTime');
          print('마지막 캔들 시간: $latestCandleTime');
          print('현재 시간: $now');
          print('시간 차이: ${timeDiff.inMinutes}분 (${timeDiff.inHours}시간)');
          print('마지막 캔들 [O:${latestCandle.open}, H:${latestCandle.high}, L:${latestCandle.low}, C:${latestCandle.close}]');
          print('==========================');
          
          // 경고: 마지막 캔들이 너무 오래된 경우
          if (timeDiff.inHours > 2 && (_selectedInterval == '30m' || _selectedInterval == '1h')) {
            print('⚠️ 경고: 마지막 캔들이 ${timeDiff.inHours}시간 전 데이터입니다. API가 최신 캔들을 반환하지 않았을 수 있습니다.');
          }
          
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
    if (_isCrypto) {
      _loadCandleData();
    } else if (_isUsStock) {
      _loadUsStockCandles();
    }
    
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
      padding: EdgeInsets.only(top: context.h(20)),
      child: HorizontalInset.text(
        child: Container(
          padding: EdgeInsets.only(bottom: 0),
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
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return HorizontalInset.custom(
      start: context.w(36),
      end: context.w(36),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0),
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

  /// 화면에 그릴 캔들 개수를 인터벌별로 결정 (제미나이 의사코드 방식)
  /// 화면을 꽉 채우도록 충분한 개수 사용
  List<CandleData> _getDisplayCandles(List<CandleData> allCandles, String interval) {
    int count = 0;
    switch (interval) {
      case '30m':
        count = 48; // 최근 24시간 (화면을 꽉 채우기 위해 충분한 개수)
        break;
      case '1h':
        count = 48; // 최근 2일 (화면을 꽉 채우기 위해 충분한 개수)
        break;
      case '4h':
        count = 42; // 최근 7일
        break;
      case '1d':
        count = 60; // 최근 2달
        break;
      default:
        count = 50;
    }
    
    // allCandles 리스트의 '마지막' 'count' 개수만큼 잘라서 반환
    if (allCandles.length <= count) {
      return allCandles;
    }
    return allCandles.sublist(allCandles.length - count);
  }

  Widget _buildCandlestickChart() {
    // 제미나이 의사코드 방식: displayCandles만 전달
    final displayCandles = _getDisplayCandles(_candleData!.candles, _selectedInterval);
    
    print('=== displayCandles 선택 ===');
    print('전체 캔들: ${_candleData!.candles.length}개');
    print('화면에 그릴 캔들: ${displayCandles.length}개');
    if (displayCandles.isNotEmpty) {
      print('첫 캔들 시간: ${DateTime.fromMillisecondsSinceEpoch(displayCandles.first.timestamp)}');
      print('마지막 캔들 시간: ${DateTime.fromMillisecondsSinceEpoch(displayCandles.last.timestamp)}');
    }
    print('========================');
    
    return CandlestickChartV2(
      candles: displayCandles, // displayCandles만 전달
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

  String _formatUsdPriceLabel(double price) {
    if (price >= 1000) {
      return '\$${_formatNumberWithComma(price)}';
    } else if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(4)}';
    }
  }

  String _formatKrwPriceLabel(double price) {
    if (_exchangeRate == null) {
      return '--';
    }
    final krwValue = price * _exchangeRate!;
    if (krwValue >= 1000) {
      return '${_formatNumberWithComma(krwValue)}원';
    } else {
      return '${krwValue.toStringAsFixed(0)}원';
    }
  }

  String _getPriceChange() {
    // 실시간 시세가 있으면 사용
    double? currentPrice;
    double? previousPrice;
    
    if (_currentRealTimePrice != null && _candleData != null && _candleData!.candles.length >= 2) {
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
        return change >= 0 ? AppColors.chartBlue : AppColors.chartRed;
      }
    }
    
    // 실시간 가격이 없으면 캔들 데이터로 비교
    if (_candleData == null || _candleData!.candles.length < 2) {
      return AppColors.gray400;
    }
    
    final currentCandle = _candleData!.candles.last;
    final previousCandle = _candleData!.candles[_candleData!.candles.length - 2];
    
    final change = currentCandle.close - previousCandle.close;
    return change >= 0 ? AppColors.chartBlue : AppColors.chartRed;
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

class _UsIntervalConfig {
  final int multiplier;
  final String timespan;
  final Duration lookback;

  const _UsIntervalConfig({
    required this.multiplier,
    required this.timespan,
    required this.lookback,
  });
  }