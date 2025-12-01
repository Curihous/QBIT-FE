import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/utils/us_stock_order_book_generator.dart';
import 'package:qbit_shared/utils/stock_price_parser.dart';
import 'package:qbit_services/websocket/us_stock_market_websocket.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 미국 주식용 가짜 호가창 위젯
class UsStockOrderBookWidget extends StatefulWidget {
  final String symbol;
  final Function(double price)? onPriceSelected;

  const UsStockOrderBookWidget({
    super.key,
    required this.symbol,
    this.onPriceSelected,
  });

  @override
  State<UsStockOrderBookWidget> createState() => _UsStockOrderBookWidgetState();
}

class _UsStockOrderBookWidgetState extends State<UsStockOrderBookWidget> {
  // 상수
  static const int _defaultVolume = 50000; // 기본 거래량 (REST API에는 거래량 정보가 없을 수 있음)
  
  UsStockOrderBookGenerator? _generator;
  UsStockMarketWebSocket? _webSocket;
  StreamSubscription<PolygonEvent>? _subscription;
  Timer? _jitterTimer;
  
  List<PseudoOrderBookLevel> _orderBookLevels = [];
  double _currentPrice = 0.0;
  double _previousPrice = 0.0;
  int _currentVolume = 0;
  bool _isLoading = true;
  bool _shouldBlink = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _startJitterTimer();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // Singleton이므로 close/dispose 하지 않음
    // 화면을 나갈 때 구독 취소
    if (widget.symbol.isNotEmpty) {
      _webSocket?.unsubscribe([widget.symbol], aggregateSecond: true);
    }
    _jitterTimer?.cancel();
    super.dispose();
  }

  /// REST API로 현재 가격 가져오기 (폴백용)
  Future<void> _loadPriceFromRestApi() async {
    try {
      debugPrint('REST API로 현재 가격 로드 시작: ${widget.symbol}');
      final quote = await StockApiService.getUsStockQuote(widget.symbol);
      
      if (mounted && quote != null) {
        double? currentPrice = StockPriceParser.parseCurrentPrice(quote);
        
        // currentPrice가 없거나 0이면 previousClose로 폴백
        if (currentPrice == null) {
          final previousClose = quote['previousClose'];
          if (previousClose != null) {
            final parsedClose = StockPriceParser.parseDouble(previousClose);
            if (parsedClose > 0) {
              currentPrice = parsedClose;
              debugPrint('REST API: currentPrice 없음, previousClose($currentPrice)로 대체');
            }
          }
        }
        
        if (currentPrice != null) {
          setState(() {
            _currentPrice = currentPrice!;
            _currentVolume = _defaultVolume;
            _isLoading = false;
            _updateOrderBook();
          });
          debugPrint('REST API로 현재 가격 로드 성공: $_currentPrice');
        } else {
          debugPrint('REST API로 가격 파싱 실패: ${quote['currentPrice']}');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        debugPrint('REST API 응답이 null');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint('REST API로 가격 로드 실패: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// WebSocket 연결 및 실시간 데이터 수신
  /// 
  /// - 실시간 데이터: Polygon WebSocket에서 Aggregate Second (A) 이벤트 수신
  /// - REST API 폴백: 10초 후에도 데이터가 없으면 REST API로 현재 가격 가져오기
  void _connectWebSocket() async {
    try {
      final apiKey = dotenv.env['POLYGON_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('Polygon API 키가 없습니다 - REST API로 폴백');
        _loadPriceFromRestApi();
        return;
      }

      // Singleton 인스턴스 사용
      _webSocket = UsStockMarketWebSocket.instance;
      
      // 연결 (이미 연결되어 있으면 무시됨)
      await _webSocket!.connect(apiKey: apiKey);
      
      // 연결 후 위젯이 dispose되었는지 확인
      if (!mounted) return;
      
      // Aggregate Second (A) 채널 구독 - 실시간 가격/거래량 수신
      _webSocket!.subscribe(
        [widget.symbol],
        trade: false,
        aggregateMinute: false,
        aggregateSecond: true,
        quote: false,
      );

      // 10초 후에도 데이터가 안 오면 REST API로 폴백
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _currentPrice == 0.0) {
          debugPrint('⚠️ 실시간 데이터 수신 없음 - REST API로 폴백');
          _loadPriceFromRestApi();
        }
      });

      // WebSocket 실시간 데이터 수신
      _subscription = _webSocket!.stream.listen(
        (event) {
          if (!mounted) return;
          
          // 내 심볼에 대한 이벤트인지 확인
          if (event.symbol != widget.symbol) return;
          
          // Aggregate Second 이벤트만 처리 (실시간 가격/거래량)
          if (event is PolygonAggregateSecond) {
            setState(() {
              _previousPrice = _currentPrice;
              _currentPrice = event.close; // 실시간 종가
              _currentVolume = event.volume; // 실시간 거래량
              _isLoading = false;
              
              // 가격 변동 시 깜빡임 효과
              if (_previousPrice > 0 && _previousPrice != _currentPrice) {
                _shouldBlink = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _shouldBlink = false;
                    });
                  }
                });
              }
              
              _updateOrderBook();
            });
          }
        },
        onError: (error) {
          debugPrint('US Stock WebSocket 스트림 에러: $error - REST API로 폴백');
          if (mounted && _currentPrice == 0.0) {
            _loadPriceFromRestApi();
          }
        },
        onDone: () {
          debugPrint('US Stock WebSocket 스트림 종료');
        },
      );
    } catch (e) {
      debugPrint('US Stock WebSocket 연결 에러: $e - REST API로 폴백');
      if (mounted && _currentPrice == 0.0) {
        _loadPriceFromRestApi();
      }
    }
  }

  /// Jitter 타이머 시작
  /// 
  /// 1초마다 호가창을 업데이트하여 거래량에 랜덤 변동을 추가 (실시간 느낌)
  /// - 실제 거래량은 변하지 않고, 표시되는 호가별 거래량 분포만 변경
  void _startJitterTimer() {
    _jitterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _currentVolume == 0 || _currentPrice <= 0) return;
      _updateOrderBook();
    });
  }

  void _updateOrderBook() {
    if (_currentPrice <= 0) return;
    
    setState(() {
      _generator = UsStockOrderBookGenerator(
        midPrice: _currentPrice,
        referencePrice: _currentPrice,
        lastVolume: _currentVolume.toDouble(),
        levelsPerSide: 8,
      );
      _orderBookLevels = _generator!.generate(jitter: 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_orderBookLevels.isEmpty) {
      return Center(
        child: Text(
          '호가 데이터 없음',
          style: AppFonts.b2Regular.copyWith(color: AppColors.gray400),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '가격(USD)',
                  style: AppFonts.c1.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.left,
                ),
                Text(
                  '수량',
                  style: AppFonts.c1.copyWith(
                    color: AppColors.gray600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          
          // 호가 리스트
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: context.h(8)),
              itemCount: _orderBookLevels.length,
              separatorBuilder: (context, index) => SizedBox(height: context.h(4)),
              itemBuilder: (context, index) {
                final level = _orderBookLevels[index];
                final isCurrentPrice = level.isMid;
                
                return _buildOrderBookRow(
                  level: level,
                  isCurrentPrice: isCurrentPrice,
                  shouldBlink: isCurrentPrice && _shouldBlink,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBookRow({
    required PseudoOrderBookLevel level,
    required bool isCurrentPrice,
    required bool shouldBlink,
  }) {
    final priceColor = level.isBid ? AppColors.chartBlue : AppColors.chartRed;
    final volumeBarColor = level.isBid ? AppColors.orderBookBidBg : AppColors.orderBookAskBg;
    final backgroundColor = isCurrentPrice 
        ? (shouldBlink ? AppColors.gray200 : AppColors.primary.withOpacity(0.1))
        : Colors.transparent;
    
    return GestureDetector(
      onTap: () {
        // 호가 터치 시 가격 입력
        widget.onPriceSelected?.call(level.price);
      },
      child: Container(
        margin: EdgeInsets.only(left: context.w(8)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 배경 거래량 바 (화면 끝까지)
            Positioned(
              right: 0,
              top: context.h(6),
              height: context.h(38),
              child: Container(
                width: context.w(150) * level.volumeFactor,
                decoration: BoxDecoration(
                  color: volumeBarColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
            ),
            
            // 호가 콘텐츠 (가격, 변동률, 거래량)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(6),
              ),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: context.h(38),
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: isCurrentPrice 
                      ? Border.all(
                          color: AppColors.primary,
                          width: 1.3,
                        )
                      : null,
                  borderRadius: isCurrentPrice ? BorderRadius.circular(4) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 좌측: 가격 + 변동률
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            level.price.toStringAsFixed(2),
                            style: AppFonts.b2Semibold.copyWith(
                              color: isCurrentPrice ? AppColors.primary : AppColors.gray900,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: context.h(0.5)),
                          Text(
                            '${level.percentFromReference >= 0 ? '+' : ''}${level.percentFromReference.toStringAsFixed(1)}%',
                            style: AppFonts.c2.copyWith(
                              color: priceColor,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    
                    // 우측: 거래량
                    Text(
                      (level.volumeFactor * _currentVolume).toInt().toString(),
                      style: AppFonts.b2Regular.copyWith(
                        color: priceColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

