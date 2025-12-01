import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_services/websocket/crypto_orderbook_websocket.dart';
import 'package:qbit_services/websocket/crypto_ticker_websocket.dart';
import 'package:qbit_shared/widgets/trade/orderbook/vertical_orderbook_widget.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_shared/utils/us_stock_order_book_generator.dart';
import 'package:qbit_shared/utils/stock_price_parser.dart';
import 'package:qbit_services/websocket/us_stock_market_websocket.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StockOrderbookTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;
  final String? binanceSymbol; // 암호화폐 WebSocket 연결용

  const StockOrderbookTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.binanceSymbol,
  });

  @override
  State<StockOrderbookTab> createState() => _StockOrderbookTabState();
}

class _StockOrderbookTabState extends State<StockOrderbookTab> {
  OrderBookModel? _orderBook;
  Map<String, dynamic>? _quote;
  bool _isLoadingOrderBook = false;
  String? _error;
  
  // Crypto
  CryptoOrderBookWebSocket? _webSocket;
  CryptoTickerWebSocket? _tickerWebSocket;
  StreamSubscription<OrderBookModel>? _orderBookSubscription;
  StreamSubscription<Map<String, dynamic>>? _tickerSubscription;

  // US Stock
  UsStockMarketWebSocket? _usWebSocket;
  StreamSubscription<PolygonEvent>? _usSubscription;
  Timer? _jitterTimer;
  UsStockOrderBookGenerator? _generator;
  double _currentPrice = 0.0;
  int _currentVolume = 0;
  static const int _defaultVolume = 50000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Crypto Clean up
    _orderBookSubscription?.cancel();
    _webSocket?.disconnect();
    _webSocket?.dispose();
    _tickerSubscription?.cancel();
    _tickerWebSocket?.disconnect();
    _tickerWebSocket?.dispose();

    // US Stock Clean up
    _usSubscription?.cancel();
    // Singleton이므로 close/dispose 하지 않음
    // 화면을 나갈 때 구독 취소
    if (widget.symbol.isNotEmpty) {
      _usWebSocket?.unsubscribe([widget.symbol], aggregateSecond: true);
    }
    _jitterTimer?.cancel();
    
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingOrderBook = true;
      _error = null;
    });

    if (widget.assetClass == 'crypto') {
      await _loadCryptoData();
    } else {
      await _loadUsStockData();
    }
  }

  Future<void> _loadCryptoData() async {
    await _loadOrderBook();
    await _connectTicker();
  }

  Future<void> _loadUsStockData() async {
    // 1. REST API로 초기 데이터 로드
    await _loadUsPriceFromRestApi();
    
    // 2. WebSocket 연결
    _connectUsWebSocket();
    
    // 3. Jitter 타이머 시작
    _startJitterTimer();
  }

  Future<void> _loadUsPriceFromRestApi() async {
    try {
      final quote = await StockApiService.getUsStockQuote(widget.symbol);
      if (mounted && quote != null) {
        final currentPrice = StockPriceParser.parseCurrentPrice(quote);
        if (currentPrice != null) {
          setState(() {
            _currentPrice = currentPrice;
            _currentVolume = _defaultVolume;
            
            // Quote 업데이트 (REST API 데이터 매핑)
            _quote = {
              'price': quote['c'] ?? quote['currentPrice'],
              'change': quote['d'] ?? quote['change'],
              'changePercent': quote['dp'] ?? quote['changePercent'],
              'high': quote['h'] ?? quote['high'],
              'low': quote['l'] ?? quote['low'],
              'volume': quote['v'] ?? quote['volume'],
              'prevClose': quote['pc'] ?? quote['prevClose'],
            };
            
            _updateUsOrderBook();
            _isLoadingOrderBook = false;
          });
        }
      }
    } catch (e) {
      print('US Stock REST API 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingOrderBook = false;
        });
      }
    }
  }

  void _connectUsWebSocket() async {
    try {
      final apiKey = dotenv.env['POLYGON_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      // Singleton 인스턴스 사용
      _usWebSocket = UsStockMarketWebSocket.instance;
      
      // 연결 (이미 연결되어 있으면 무시됨)
      await _usWebSocket!.connect(apiKey: apiKey);
      
      if (!mounted) return;
      
      _usWebSocket!.subscribe(
        [widget.symbol],
        trade: false,
        aggregateMinute: false,
        aggregateSecond: true,
        quote: false,
      );

      _usSubscription = _usWebSocket!.stream.listen((event) {
        if (!mounted) return;
        
        // 내 심볼에 대한 이벤트인지 확인
        if (event.symbol != widget.symbol) return;
        
        if (event is PolygonAggregateSecond) {
          setState(() {
            _currentPrice = event.close;
            _currentVolume = event.volume;
            
            // Quote 업데이트
            _quote = {
              'price': event.close,
              'high': event.high,
              'low': event.low,
              'volume': event.volume,
              // 변동폭/률은 이전 종가(prevClose)가 있어야 정확함. 
              // 여기서는 REST API에서 받은 prevClose를 유지하거나 별도로 계산해야 함.
              // 일단 기존 _quote의 prevClose를 유지
              'prevClose': _quote?['prevClose'] ?? event.open, // fallback
            };
            
            // 변동률 재계산
            if (_quote != null && _quote!['prevClose'] != null) {
              final prevClose = _parseDouble(_quote!['prevClose']);
              if (prevClose > 0) {
                final change = _currentPrice - prevClose;
                final changePercent = (change / prevClose) * 100;
                _quote!['change'] = change;
                _quote!['changePercent'] = changePercent;
              }
            }

            _updateUsOrderBook();
            _isLoadingOrderBook = false;
          });
        }
      });
    } catch (e) {
      print('US Stock WebSocket 연결 실패: $e');
    }
  }

  void _startJitterTimer() {
    _jitterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _currentVolume == 0 || _currentPrice <= 0) return;
      _updateUsOrderBook();
    });
  }

  void _updateUsOrderBook() {
    if (_currentPrice <= 0) return;
    
    _generator = UsStockOrderBookGenerator(
      midPrice: _currentPrice,
      referencePrice: _currentPrice,
      lastVolume: _currentVolume.toDouble(),
      levelsPerSide: 10, // 10단계
    );
    
    final levels = _generator!.generate(jitter: 1.0);
    
    // PseudoOrderBookLevel -> OrderBookModel 변환
    final bids = levels.where((l) => l.isBid).map((l) => {
      'price': l.price.toString(),
      'quantity': (l.volumeFactor * _currentVolume).toString(),
    }).toList();
    
    final asks = levels.where((l) => !l.isBid && !l.isMid).map((l) => {
      'price': l.price.toString(),
      'quantity': (l.volumeFactor * _currentVolume).toString(),
    }).toList();

    // Asks는 가격 오름차순 (낮은 가격이 아래, 높은 가격이 위? OrderBookModel은 보통 리스트 순서대로 위에서 아래로 렌더링됨)
    // VerticalOrderBookWidget은 Asks를 역순으로 표시(Bottom-up)하거나 정렬을 기대함.
    // 보통 Asks: [Lowest Ask, ..., Highest Ask]
    // Bids: [Highest Bid, ..., Lowest Bid]
    // UsStockOrderBookGenerator returns sorted by price descending? No, let's check.
    // But let's ensure sorting.
    
    // Sort Asks: Price Ascending (Lowest price first - best ask)
    asks.sort((a, b) => double.parse(a['price']!).compareTo(double.parse(b['price']!)));
    
    // Sort Bids: Price Descending (Highest price first - best bid)
    bids.sort((a, b) => double.parse(b['price']!).compareTo(double.parse(a['price']!)));

    setState(() {
      _orderBook = OrderBookModel.fromJson({
        'symbol': widget.symbol,
        'bids': bids,
        'asks': asks,
      });
    });
  }

  Future<void> _connectTicker() async {
    try {
      final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
      
      _tickerWebSocket?.dispose();
      _tickerWebSocket = CryptoTickerWebSocket();
      await _tickerWebSocket!.connect(binanceSymbol);
      
      _tickerSubscription = _tickerWebSocket!.tickerStream.listen((data) {
        if (mounted) {
          setState(() {
            _quote = data;
          });
        }
      });
    } catch (e) {
      print('Ticker WebSocket 연결 실패: $e');
    }
  }

  Future<void> _loadOrderBook() async {
    // ... (Existing Crypto Logic)
    // Simplified for brevity, keeping existing logic but ensuring it's called only for crypto
    try {
      final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
      if (binanceSymbol.isEmpty) return;
      
      _orderBookSubscription?.cancel();
      _webSocket?.disconnect();
      
      _webSocket = CryptoOrderBookWebSocket();
      await _webSocket!.connect(binanceSymbol);
      
      _orderBookSubscription = _webSocket!.orderBookStream.listen((updatedOrderBook) {
        if (mounted) {
          setState(() {
            _orderBook = updatedOrderBook;
            _isLoadingOrderBook = false;
          });
        }
      });
    } catch (e) {
      print('Crypto Orderbook Error: $e');
      if (mounted) setState(() => _isLoadingOrderBook = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOrderBook && _orderBook == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null && _orderBook == null) {
      return Center(
        child: Text(_error!),
      );
    }

    // Unified Widget for BOTH Crypto and US Stock
    return VerticalOrderBookWidget(
      symbol: widget.symbol,
      orderBook: _orderBook,
      quote: _quote,
      isLoading: _isLoadingOrderBook,
      onRefresh: () async {
        if (widget.assetClass == 'crypto') {
          await _webSocket?.disconnect();
          await _loadCryptoData();
        } else {
          await _loadUsStockData();
        }
      },
    );
  }
}
