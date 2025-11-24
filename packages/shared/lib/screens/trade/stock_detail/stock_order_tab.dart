import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_services/api/exchange_rate_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/websocket/crypto_orderbook_websocket.dart';
import 'package:qbit_services/websocket/crypto_market_websocket.dart';
import 'package:qbit_services/websocket/us_stock_market_websocket.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qbit_shared/widgets/trade/orderbook/vertical_orderbook_widget.dart';
import 'package:qbit_shared/widgets/trade/orderbook/us_stock_orderbook_widget.dart';
import 'package:qbit_services/models/stock_detail_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/utils/stock_price_parser.dart';
import 'package:logger/logger.dart';
import 'package:qbit_shared/screens/trade/stock_detail/order_forms/crypto_order_form.dart';
import 'package:qbit_shared/screens/trade/stock_detail/order_forms/stock_order_form.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:go_router/go_router.dart';

// OrderModel - API 응답 데이터 모델 (주문 내역용)
class OrderHistoryModel {
  final int orderId;
  final String alpacaOrderId;
  final String symbol;
  final String side;
  final String quantity;
  final String filledQuantity;
  final String? filledAvgPrice;
  final String type;
  final String timeInForce;
  final String? limitPrice;
  final String? stopPrice;
  final String status;
  final String createdAt;
  final String submittedAt;
  final String? filledAt;
  final String? canceledAt;
  final String? replacedAt;
  final String? replacedBy;
  final String? replaces;

  OrderHistoryModel({
    required this.orderId,
    required this.alpacaOrderId,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.filledQuantity,
    this.filledAvgPrice,
    required this.type,
    required this.timeInForce,
    this.limitPrice,
    this.stopPrice,
    required this.status,
    required this.createdAt,
    required this.submittedAt,
    this.filledAt,
    this.canceledAt,
    this.replacedAt,
    this.replacedBy,
    this.replaces,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    // 필수 필드 검증
    final requiredFields = [
      'orderId', 'alpacaOrderId', 'symbol', 'side', 'quantity',
      'filledQuantity', 'type', 'timeInForce', 'status', 'createdAt', 'submittedAt'
    ];
    
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw FormatException('필수 필드가 누락되었거나 null입니다: $field');
      }
    }
    
    // 타입 안전한 파싱
    int parseOrderId(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        throw FormatException('orderId 파싱 실패: $value');
      }
      throw FormatException('orderId 타입이 올바르지 않습니다: ${value.runtimeType}');
    }
    
    String parseString(dynamic value, String fieldName) {
      if (value == null) throw FormatException('$fieldName이 null입니다');
      return value.toString();
    }
    
    return OrderHistoryModel(
      orderId: parseOrderId(json['orderId']),
      alpacaOrderId: parseString(json['alpacaOrderId'], 'alpacaOrderId'),
      symbol: parseString(json['symbol'], 'symbol'),
      side: parseString(json['side'], 'side'),
      quantity: parseString(json['quantity'], 'quantity'),
      filledQuantity: parseString(json['filledQuantity'], 'filledQuantity'),
      filledAvgPrice: json['filledAvgPrice']?.toString(),
      type: parseString(json['type'], 'type'),
      timeInForce: parseString(json['timeInForce'], 'timeInForce'),
      limitPrice: json['limitPrice']?.toString(),
      stopPrice: json['stopPrice']?.toString(),
      status: parseString(json['status'], 'status'),
      createdAt: parseString(json['createdAt'], 'createdAt'),
      submittedAt: parseString(json['submittedAt'], 'submittedAt'),
      filledAt: json['filledAt']?.toString(),
      canceledAt: json['canceledAt']?.toString(),
      replacedAt: json['replacedAt']?.toString(),
      replacedBy: json['replacedBy']?.toString(),
      replaces: json['replaces']?.toString(),
    );
  }
}

class StockOrderTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;
  final String? binanceSymbol; // 암호화폐 WebSocket 연결용

  const StockOrderTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.binanceSymbol,
  });

  @override
  State<StockOrderTab> createState() => _StockOrderTabState();
}

class _StockOrderTabState extends State<StockOrderTab> {
  OrderBookModel? _orderBook;
  bool _isLoading = true;
  bool _isLoadingOrderBook = false;
  String? _error;
  CryptoOrderBookWebSocket? _webSocket;
  CryptoMarketWebSocket? _marketWebSocket; // 암호화폐 시장가용 WebSocket
  UsStockMarketWebSocket? _usStockMarketWebSocket; // 미국 주식 시장가용 WebSocket
  StreamSubscription<OrderBookModel>? _orderBookSubscription; // 호가창 WebSocket 구독
  StreamSubscription<double>? _marketPriceSubscription; // 암호화폐 시장가 WebSocket 구독
  StreamSubscription<PolygonEvent>? _usStockPriceSubscription; // 미국 주식 시장가 WebSocket 구독
  
  // 주문 관련 상태
  int _quantity = 1;
  double _price = 0.0;
  String _selectedOrderTab = '매수'; // '매수', '매도', '내역'
  String _selectedOrderType = '지정가'; // '지정가', '시장가'
  
  // 시장가 주문용 USDT 금액
  double _marketOrderAmount = 1.0;
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _marketAmountController = TextEditingController();
  
  // 스크롤 컨트롤러 
  final ScrollController _scrollController = ScrollController();
  
  // 포커스 노드 추가
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _marketAmountFocusNode = FocusNode();
  
  // 환율 관련
  double? _exchangeRate;
  double? _tickSizeInKrw;
  
  // 통화 전환 상태
  bool _isShowingKRW = true; // true: 원화, false: 달러
  
  // 주문 제출 상태
  bool _isSubmittingOrder = false;
  
  // 현재 시장 가격 (시장가 주문용)
  double _currentMarketPrice = 0.0;
  
  // REST API 재시도 카운트
  int _marketPriceRetryCount = 0;
  static const int _maxRetries = 3;
  
  // 종목 상세 정보
  StockDetailModel? _stockDetail;
  
  // Logger 인스턴스
  final Logger logger = Logger();
  
  // 내역 탭 관련 상태
  List<OrderHistoryModel> _orderHistory = [];
  bool _isLoadingHistory = false;
  String _historyFilter = '전체'; // 전체, 매수, 매도
  
  // 포지션 정보
  double? _buyingPower; // 매수 가능 금액 (USD)
  double? _positionQuantity; // 보유 수량
  
  // StockOrderForm의 상태에 접근하기 위한 GlobalKey
  final GlobalKey<StockOrderFormState> _stockOrderFormKey = GlobalKey<StockOrderFormState>();

  @override
  void initState() {
    super.initState();
    _quantityController.text = '';
    _priceController.text = '';
    _marketAmountController.text = '1.0';
    
    // 포커스 노드에 리스너 추가
    _quantityFocusNode.addListener(_onFocusChange);
    _priceFocusNode.addListener(_onFocusChange);
    _marketAmountFocusNode.addListener(_onFocusChange);
    
    _loadData();
  }
  
  void _onFocusChange() {
    if (_quantityFocusNode.hasFocus || _priceFocusNode.hasFocus || _marketAmountFocusNode.hasFocus) {
      // 포커스가 있을 때 약간의 딜레이 후 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    // WebSocket 구독 취소
    _orderBookSubscription?.cancel();
    _marketPriceSubscription?.cancel();
    _usStockPriceSubscription?.cancel();
    
    // WebSocket 연결 해제
    _webSocket?.disconnect();
    _webSocket?.dispose();
    _marketWebSocket?.disconnect();
    _marketWebSocket?.dispose();
    _usStockMarketWebSocket?.close();
    
    _quantityController.dispose();
    _priceController.dispose();
    _marketAmountController.dispose();
    _scrollController.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _marketAmountFocusNode.dispose();
    super.dispose();
  }

  /// 통화 전환 메서드
  Future<void> _toggleCurrency() async {
    if (widget.assetClass != 'stock' || _exchangeRate == null) return;
    
    final rate = _exchangeRate!;
    
    setState(() {
      _isShowingKRW = !_isShowingKRW;
      
      if (_isShowingKRW) {
        // 달러 -> 원화 변환
        final usdValue = _price;
        final krwValue = usdValue * rate;
        _price = krwValue;
        _priceController.text = krwValue.toStringAsFixed(0);
      } else {
        // 원화 -> 달러 변환
        final krwValue = _price;
        final usdValue = krwValue / rate;
        _price = usdValue;
        _priceController.text = usdValue.toStringAsFixed(2);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 토큰 상태 확인
      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _error = '로그인이 필요합니다. Alpaca 계정을 연동해주세요.';
          _isLoading = false;
        });
        return;
      }

      // 환율 로드 (에러 처리 추가)
      try {
        _exchangeRate = await ExchangeRateApiService.getUsdToKrwRate();
        if (!mounted) return;
        
        _tickSizeInKrw = await ExchangeRateApiService.getTickSizeInKrw();
        if (!mounted) return;
      } catch (e) {
        print('환율 로드 에러: $e');
        // 환율 로드 실패해도 계속 진행
      }

      // 호가창 데이터 로드
      await _loadOrderBook();
      
      // 현재 시장 가격 로드
      await _loadCurrentMarketPrice();
      
      // 종목 상세 정보 로드
      await _loadStockDetail();
      
      // 포지션 정보 로드
      await _loadPositionInfo();
    } catch (error) {
      if (!mounted) return;
      
      String errorMessage = '오류가 발생했습니다';
      if (error.toString().contains('401')) {
        errorMessage = '인증 오류가 발생했습니다. Alpaca 계정 연동을 확인해주세요.';
      } else if (error.toString().contains('timeout') || error.toString().contains('초과')) {
        errorMessage = '요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.';
      } else {
        errorMessage = '오류가 발생했습니다: ${error.toString().split('\n').first}';
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }
  
  /// REST API로 시장 가격 로드 (폴백용)
  Future<void> _loadMarketPriceFromRestApi() async {
    // 최대 재시도 횟수 확인
    if (_marketPriceRetryCount >= _maxRetries) {
      logger.w('최대 재시도 횟수 초과, REST API 폴백 중단');
      return;
    }
    
    _marketPriceRetryCount++;
    
    try {
      logger.i('REST API로 시장 가격 로드 시작: ${widget.symbol} (재시도: $_marketPriceRetryCount/$_maxRetries)');
      final quote = await StockApiService.getUsStockQuote(widget.symbol);
      logger.i('REST API 응답: $quote');
      
      if (mounted && quote != null) {
        final currentPrice = StockPriceParser.parseCurrentPrice(quote);
        
        if (currentPrice != null) {
          setState(() {
            _currentMarketPrice = currentPrice;
            _marketPriceRetryCount = 0; // 성공 시 재시도 카운트 리셋
          });
          logger.i('미국 주식 현재 가격 로드 성공 (REST API): $_currentMarketPrice');
        } else {
          logger.w('currentPrice 파싱 실패 또는 0 이하: ${quote['currentPrice']}');
        }
      } else {
        logger.w('REST API 응답이 null이거나 mounted가 false');
      }
    } catch (error) {
      logger.e('REST API로 시장 가격 로드 실패: $error');
      // 실패 시 호가창에서 계산 (fallback)
      if (mounted && _orderBook != null && _orderBook!.bids.isNotEmpty && _orderBook!.asks.isNotEmpty) {
        final bestBid = _orderBook!.bids.first.price;
        final bestAsk = _orderBook!.asks.first.price;
        setState(() {
          _currentMarketPrice = (bestBid + bestAsk) / 2;
          _marketPriceRetryCount = 0; // 호가창에서 가격을 가져왔으므로 재시도 카운트 리셋
        });
        logger.i('호가창에서 현재 가격 계산: $_currentMarketPrice');
      }
    }
  }
  
  /// 현재 시장 가격 로드 (WebSocket ticker에서 직접 가져오기)
  Future<void> _loadCurrentMarketPrice() async {
    try {
      if (widget.assetClass == 'crypto') {
        // 암호화폐: WebSocket ticker에서 현재가 가져오기
        // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
        final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
        if (binanceSymbol.isNotEmpty) {
          // 기존 WebSocket 연결 해제 및 구독 취소
          _marketPriceSubscription?.cancel();
          await _marketWebSocket?.disconnect();
          _marketWebSocket?.dispose();
          
          // 새로운 WebSocket 연결
          _marketWebSocket = CryptoMarketWebSocket();
          await _marketWebSocket!.connect(binanceSymbol);
          
          // WebSocket에서 실시간 가격 받기 (구독 저장)
          _marketPriceSubscription = _marketWebSocket!.lastPriceStream.listen((price) {
            if (mounted) {
              setState(() {
                _currentMarketPrice = price;
              });
            }
          });
        } else {
          // binanceSymbol이 없으면 호가창에서 계산 (fallback)
          if (mounted && _orderBook != null && _orderBook!.bids.isNotEmpty && _orderBook!.asks.isNotEmpty) {
            final bestBid = _orderBook!.bids.first.price;
            final bestAsk = _orderBook!.asks.first.price;
            setState(() {
              _currentMarketPrice = (bestBid + bestAsk) / 2; // 중간가격
            });
          }
        }
      } else {
        // 주식: REST API로 먼저 초기 가격 가져오기 (빠른 초기화), 그 다음 WebSocket으로 실시간 업데이트
        try {
          // 1. REST API로 먼저 초기 가격 가져오기 (즉시 반영)
          await _loadMarketPriceFromRestApi();
          
          // 2. WebSocket 연결 시도 (실시간 업데이트용)
          final apiKey = dotenv.env['POLYGON_API_KEY'];
          if (apiKey != null && apiKey.isNotEmpty) {
            try {
              // 기존 WebSocket 연결 해제
              _usStockPriceSubscription?.cancel();
              await _usStockMarketWebSocket?.close();
              
              // 새로운 WebSocket 연결
              _usStockMarketWebSocket = UsStockMarketWebSocket(apiKey);
              await _usStockMarketWebSocket!.connect(initialSymbols: [widget.symbol]);
              _usStockMarketWebSocket!.subscribe([widget.symbol], trade: true, quote: true);
              
              // WebSocket에서 실시간 가격 받기
              _usStockPriceSubscription = _usStockMarketWebSocket!.stream.listen((event) {
                if (mounted) {
                  double? price;
                  if (event is PolygonTrade) {
                    price = event.price;
                  } else if (event is PolygonQuote) {
                    // Quote의 경우 bid/ask 중간값 사용
                    price = (event.bidPrice + event.askPrice) / 2;
                  }
                  
                  if (price != null && price > 0) {
                    setState(() {
                      _currentMarketPrice = price!;
                    });
                    logger.i('미국 주식 현재 가격 업데이트 (WebSocket): $_currentMarketPrice');
                  }
                }
              }, onError: (error) {
                logger.w('WebSocket 스트림 에러: $error');
                // 재시도 제한 확인 후 REST API로 폴백
                if (_marketPriceRetryCount < _maxRetries && _currentMarketPrice == 0.0) {
                  _loadMarketPriceFromRestApi();
                }
              });
            } catch (wsError) {
              logger.w('WebSocket 연결 실패, REST API만 사용: $wsError');
              // WebSocket 실패해도 REST API로 이미 가격을 가져왔으므로 문제없음
            }
          }
        } catch (error) {
          logger.e('미국 주식 현재 가격 로드 실패: $error');
          // 실패 시 호가창에서 계산 (fallback)
          if (mounted && _orderBook != null && _orderBook!.bids.isNotEmpty && _orderBook!.asks.isNotEmpty) {
            final bestBid = _orderBook!.bids.first.price;
            final bestAsk = _orderBook!.asks.first.price;
            setState(() {
              _currentMarketPrice = (bestBid + bestAsk) / 2;
            });
            logger.i('호가창에서 현재 가격 계산: $_currentMarketPrice');
          }
        }
      }
    } catch (error) {
      print('현재 시장 가격 로드 실패: $error');
      // 실패 시 호가창에서 계산 (fallback)
      if (mounted) {
        if (widget.assetClass == 'crypto' && 
            _orderBook != null && 
            _orderBook!.bids.isNotEmpty && 
            _orderBook!.asks.isNotEmpty) {
          final bestBid = _orderBook!.bids.first.price;
          final bestAsk = _orderBook!.asks.first.price;
          setState(() {
            _currentMarketPrice = (bestBid + bestAsk) / 2;
          });
        }
        // fallback이 실패한 경우에는 기존 값 유지 (setState 불필요)
      }
    }
  }

  /// 종목 상세 정보 로드
  Future<void> _loadStockDetail() async {
    try {
      // 심볼 정규화: 중복 슬래시 제거
      String normalizedSymbol = widget.symbol.replaceAll('//', '/');
      logger.i('종목 상세 정보 로드 시작: ${widget.symbol} -> $normalizedSymbol');
      _stockDetail = await StockApiService.getStockDetail(normalizedSymbol);
      
      if (_stockDetail != null) {
        logger.i('종목 상세 정보 로드 성공');
        logger.i('자산 클래스: ${_stockDetail!.assetClass}');
        logger.i('최소 주문 수량: ${_stockDetail!.minOrderSize}');
        logger.i('최소 거래 증분: ${_stockDetail!.minTradeIncrement}');
        logger.i('가격 증분: ${_stockDetail!.priceIncrement}');
      } else {
        logger.e('종목 상세 정보 로드 실패');
      }
    } catch (error) {
      logger.e('종목 상세 정보 로드 에러: $error');
    }
  }
  
  /// 포지션 정보 로드 (매수 가능 금액 및 보유 수량)
  Future<void> _loadPositionInfo() async {
    try {
      logger.i('포지션 정보 로드 시작: ${widget.symbol}');
      
      final response = await StockApiService.getPositionDetail(widget.symbol);
      
      if (!mounted) return;
      
      if (response != null) {
        setState(() {
          _buyingPower = response['account']?['buyingPower'] != null 
              ? double.tryParse(response['account']['buyingPower'].toString())
              : null;
          _positionQuantity = response['position']?['quantity'] != null
              ? double.tryParse(response['position']['quantity'].toString())
              : null;
        });
        
        logger.i('포지션 정보 로드 성공');
        logger.i('매수 가능 금액: $_buyingPower USD');
        logger.i('보유 수량: $_positionQuantity');
      } else {
        logger.e('포지션 정보 로드 실패');
      }
    } catch (error) {
      logger.e('포지션 정보 로드 에러: $error');
    }
  }
  
  /// 주문 내역 조회
  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      // 심볼 정규화
      String querySymbol = widget.symbol;
      
      // 암호화폐의 경우 USDT를 USD로 변환
      if (widget.assetClass == 'crypto') {
        if (querySymbol.contains('USDT')) {
          querySymbol = querySymbol.replaceAll('USDT', 'USD');
        } else if (querySymbol.contains('USDC')) {
          querySymbol = querySymbol.replaceAll('USDC', 'USD');
        }
        
        // 슬래시가 없으면 추가
        if (!querySymbol.contains('/') && querySymbol.endsWith('USD')) {
          final baseCurrency = querySymbol.substring(0, querySymbol.length - 3);
          querySymbol = '$baseCurrency/USD';
        }
      }
      
      logger.i('주문 내역 조회 시작: $querySymbol');
      
      final response = await OrderApiService.getOrderHistory(
        symbol: querySymbol,
        status: null,
      );
      
      if (!mounted) return;
      
      if (response != null) {
        List<OrderHistoryModel> orders = [];
        
        if (response['content'] != null) {
          // 각 항목에 대해 try/catch를 사용하여 유효하지 않은 항목은 건너뛰기
          for (final item in response['content'] as List) {
            try {
              if (item is Map<String, dynamic>) {
                final order = OrderHistoryModel.fromJson(item);
                orders.add(order);
              } else {
                logger.w('주문 내역 항목이 Map이 아닙니다: ${item.runtimeType}');
              }
            } catch (e) {
              logger.w('주문 내역 항목 파싱 실패, 건너뜀: $e');
              // 유효하지 않은 항목은 건너뛰고 계속 진행
            }
          }
        }
        
        // 필터링 (대소문자 정규화)
        if (_historyFilter == '매수') {
          orders = orders.where((order) {
            final side = order.side.toLowerCase();
            return side == 'buy';
          }).toList();
        } else if (_historyFilter == '매도') {
          orders = orders.where((order) {
            final side = order.side.toLowerCase();
            return side == 'sell';
          }).toList();
        }
        
        // 최신순 정렬
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        setState(() {
          _orderHistory = orders;
          _isLoadingHistory = false;
        });
        
        logger.i('주문 내역 로드 완료: ${orders.length}개');
      } else {
        setState(() {
          _isLoadingHistory = false;
        });
        logger.w('주문 내역 응답이 null입니다');
      }
    } catch (error) {
      logger.e('주문 내역 조회 에러: $error');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }
  
  // 유틸리티 함수들
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--.--.--';
    }
  }
  
  String _getStatusLabel(OrderHistoryModel order) {
    final status = order.status.toLowerCase();
    final side = order.side.toLowerCase(); // 대소문자 정규화
    final filledQuantity = double.tryParse(order.filledQuantity) ?? 0.0;
    final quantity = double.tryParse(order.quantity) ?? 0.0;
    
    if (status == 'canceled' || status == 'cancelled') {
      return '취소됨';
    }
    
    if (filledQuantity > 0) {
      if (filledQuantity >= quantity) {
        return side == 'buy' ? '매수 완료' : '매도 완료';
      } else {
        return side == 'buy' ? '매수 부분체결' : '매도 부분체결';
      }
    }
    
    if (status == 'filled' || status == 'partially_filled') {
      if (status == 'partially_filled') {
        return side == 'buy' ? '매수 부분체결' : '매도 부분체결';
      } else {
        return side == 'buy' ? '매수 완료' : '매도 완료';
      }
    } else if (status == 'accepted' || status == 'pending_new' || status == 'new') {
      return order.type == 'limit' ? '지정가 대기' : '시장가 대기';
    } else {
      return '처리 중';
    }
  }
  
  Color _getStatusColor(OrderHistoryModel order) {
    final status = order.status.toLowerCase();
    final side = order.side.toLowerCase(); // 대소문자 정규화
    final filledQuantity = double.tryParse(order.filledQuantity) ?? 0.0;
    
    if (status == 'canceled' || status == 'cancelled') {
      return AppColors.gray600;
    }
    
    if (filledQuantity > 0) {
      return side == 'buy' ? AppColors.chartRed : AppColors.chartBlue;
    }
    
    if (status == 'filled' || status == 'partially_filled') {
      return side == 'buy' ? AppColors.chartRed : AppColors.chartBlue;
    } else if (status == 'accepted' || status == 'pending_new' || status == 'new') {
      return AppColors.primary;
    } else {
      return AppColors.primary;
    }
  }
  
  String _formatQuantityAndPrice(OrderHistoryModel order) {
    final quantity = double.tryParse(order.quantity) ?? 0;
    final price = order.filledAvgPrice != null 
        ? double.tryParse(order.filledAvgPrice!) 
        : order.limitPrice != null 
            ? double.tryParse(order.limitPrice!) 
            : null;
    
    final isCrypto = widget.assetClass == 'crypto';
    
    final quantityText = isCrypto 
        ? '${quantity.toStringAsFixed(9).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}개'
        : '${quantity.toStringAsFixed(0)}주';
    
    if (price != null) {
      final priceText = '\$${price.toStringAsFixed(2)}';
      return '$quantityText · $priceText';
    } else {
      return quantityText;
    }
  }

  Future<void> _loadOrderBook() async {
    setState(() {
      _isLoadingOrderBook = true;
      _isLoading = true;
    });

    try {
      // 1. 초기 스냅샷 로드 - 자산군별 분기 필요
      OrderBookModel? orderBook;
      if (widget.assetClass == 'crypto') {
        // 암호화폐 호가창 (현재 지원)
        // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
        final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
        if (binanceSymbol.isEmpty) {
          if (mounted) {
            setState(() {
              _isLoadingOrderBook = false;
              _isLoading = false;
            });
          }
          return;
        }
        
        orderBook = await StockApiService.getCryptoOrderBook(binanceSymbol)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => null,
            );
      } else {
        // TODO: Polygon API 결제 후 미국 주식 호가창 지원 예정
        // orderBook = await StockApiService.getStockOrderBook(widget.symbol)
        //     .timeout(
        //       const Duration(seconds: 10),
        //       onTimeout: () => null,
        //     );
        orderBook = null; // 현재는 비크립토 호가창 미지원
      }
      
      if (mounted) {
        setState(() {
          _orderBook = orderBook;
          _isLoadingOrderBook = false;
          _isLoading = false;
        });
      }

      // 2. WebSocket 연결 시작 
      if (widget.assetClass == 'crypto' && mounted) {
        // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
        final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
        if (binanceSymbol.isNotEmpty) {
          // 기존 WebSocket 연결 해제 및 구독 취소
          _orderBookSubscription?.cancel();
          await _webSocket?.disconnect();
          _webSocket?.dispose();
          
          // 새로운 WebSocket 연결
          _webSocket = CryptoOrderBookWebSocket();
          await _webSocket!.connect(binanceSymbol);
          
          // WebSocket 스트림 구독 (구독 저장)
          _orderBookSubscription = _webSocket!.orderBookStream.listen((updatedOrderBook) {
            if (mounted) {
              setState(() {
                _orderBook = updatedOrderBook;
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orderBook = null;
          _isLoadingOrderBook = false;
          _isLoading = false;
        });
      }
      print('호가창 데이터 로드 중 에러: $e');
    }
  }

  Future<void> _handleOrderSubmit() async {
    // 입력 검증
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수량은 1주 이상이어야 합니다'),
          backgroundColor: AppColors.chartRed,
        ),
      );
      return;
    }
    
    // 지정가 주문일 때만 가격 검증
    if (_selectedOrderType == '지정가' && _price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가격을 입력해주세요'),
          backgroundColor: AppColors.chartRed,
        ),
      );
      return;
    }
    
    // 시장가 주문일 때 USDT 금액 검증 (암호화폐만)
    if (_selectedOrderType == '시장가' && widget.assetClass == 'crypto' && _marketOrderAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('USDT 금액을 입력해주세요'),
          backgroundColor: AppColors.chartRed,
        ),
      );
      return;
    }
    
    // 환율 확인
    if (_exchangeRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요'),
          backgroundColor: AppColors.chartRed,
        ),
      );
      return;
    }

    try {
      // 주문 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('주문 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('종목: ${widget.symbol}'),
              Text('구분: $_selectedOrderTab'),
              Text('주문타입: $_selectedOrderType'),
              if (widget.assetClass == 'crypto' && _selectedOrderType == '지정가') ...[
                Text('수량: ${(_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizeQuantity(_quantity.toDouble()).toStringAsFixed(9)}개'),
                Text('가격: ${(_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizePrice(_price).toStringAsFixed(2)} USD'),
                Text('총액: ${((_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizeQuantity(_quantity.toDouble()) * (_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizePrice(_price)).toStringAsFixed(2)} USD'),
              ] else if (widget.assetClass == 'crypto' && _selectedOrderType == '시장가') ...[
                Text('금액: ${_marketOrderAmount.toStringAsFixed(2)} USDT'),
                Text('예상 수량: ${(_marketOrderAmount / _currentMarketPrice).toStringAsFixed(9)}개'),
                Text('가격: 시장가'),
              ] else ...[
                Text('수량: $_quantity주'),
                Text('가격: ${_price.toStringAsFixed(0)}원'),
                Text('총액: ${(_quantity * _price).toStringAsFixed(0)}원'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('확인'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 로딩 상태 시작
      setState(() {
        _isSubmittingOrder = true;
      });

      // 주문 생성
      String? limitPrice;
      OrderType orderType;
      TimeInForce timeInForce;
      String quantity = _quantity.toString();
      
      if (_selectedOrderType == '시장가') {
        orderType = OrderType.market;
        limitPrice = null; // 시장가는 가격 지정 불필요
        timeInForce = widget.assetClass == 'crypto' ? TimeInForce.gtc : TimeInForce.day;
        
        if (widget.assetClass == 'crypto') {
          // 암호화폐 시장가: USDT 금액 기반으로 수량 계산
          final rules = _stockDetail?.toOrderRules() ?? OrderRules.crypto(
            minOrderSize: 0.000223249,
            minTradeIncrement: 0.000000001,
            priceIncrement: 0.01,
          );
          final estimatedQty = _marketOrderAmount / _currentMarketPrice;
          final minQty = rules.minPassingQtyAtPrice(_currentMarketPrice);
          final finalQty = estimatedQty > minQty ? estimatedQty : minQty;
          quantity = finalQty.toStringAsFixed(9);
        }
      } else {
        orderType = OrderType.limit;
        timeInForce = widget.assetClass == 'crypto' ? TimeInForce.gtc : TimeInForce.day;
        
        if (widget.assetClass == 'crypto') {
          // 암호화폐 지정가: 동적 규칙 적용
          final rules = _stockDetail?.toOrderRules() ?? OrderRules.crypto(
            minOrderSize: 0.000223249,
            minTradeIncrement: 0.000000001,
            priceIncrement: 0.01,
          );
          
          // 가격 정규화
          final normalizedPrice = rules.normalizePrice(_price);
          
          // 수량 정규화 및 최소 체결금액 보장
          final normalizedQty = rules.normalizeQuantity(_quantity.toDouble());
          final minPassingQty = rules.minPassingQtyAtPrice(normalizedPrice);
          final finalQty = normalizedQty > minPassingQty ? normalizedQty : minPassingQty;
          
          limitPrice = normalizedPrice.toStringAsFixed(2);
          quantity = finalQty.toStringAsFixed(9);
          
          // 유효성 검사 (최소 수량 확인)
          final validation = rules.validateOrder(
            quantity: finalQty,
            price: normalizedPrice,
            isMarketOrder: false,
          );
          
          if (!validation.isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('주문 검증 실패: ${validation.errors.join(', ')}\n최소 주문 수량: ${rules.minOrderSize}개'),
                backgroundColor: AppColors.chartRed,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }
        } else {
          // 주식: KRW를 USD로 변환
          final exchangeRate = _exchangeRate ?? 1300.0;
          final priceInUsd = _price / exchangeRate;
          limitPrice = priceInUsd.toStringAsFixed(2);
        }
      }
      
      // 심볼 형식 변환 (BTCUSDT -> BTC/USD, ETH/USDT -> ETH/USD)
      String apiSymbol = widget.symbol;
      
      if (widget.assetClass == 'crypto') {
        // 1. USDT를 USD로 변환 (ETHUSDT -> ETHUSD, ETH/USDT -> ETH/USD)
        if (apiSymbol.contains('USDT')) {
          apiSymbol = apiSymbol.replaceAll('USDT', 'USD');
        } else if (apiSymbol.contains('USDC')) {
          apiSymbol = apiSymbol.replaceAll('USDC', 'USD');
        }
        
        // 2. 슬래시가 없으면 추가 (BTCUSD -> BTC/USD, ETHUSD -> ETH/USD)
        if (!apiSymbol.contains('/') && apiSymbol.endsWith('USD')) {
          final baseCurrency = apiSymbol.substring(0, apiSymbol.length - 3);
          apiSymbol = '$baseCurrency/USD';
        }
      }
      
      final order = OrderRequest(
        symbol: apiSymbol,
        quantity: quantity,
        side: _selectedOrderTab == '매도' ? OrderSide.sell : OrderSide.buy,
        type: orderType,
        timeInForce: timeInForce,
        limitPrice: limitPrice,
      );

      // 원본 수량 저장 (주문 내역 표시용)
      final originalQuantity = widget.assetClass == 'crypto' && _selectedOrderType == '지정가' 
          ? _quantityController.text
          : quantity;
      
      // 주문 요청 로그 출력
      print('=== 주문 요청 정보 ===');
      print('원본 심볼: ${widget.symbol}');
      print('API 심볼: $apiSymbol');
      print('원본 수량: $originalQuantity');
      print('서버 전송 수량: $quantity');
      print('방향: ${_selectedOrderTab == '매도' ? 'sell' : 'buy'}');
      print('타입: ${orderType.name}');
      print('유효기간: ${timeInForce.name}');
      print('지정가: $limitPrice');
      print('주문 데이터: ${order.toJson()}');
      print('==================');

      final result = await OrderApiService.createOrder(order);
      
      if (!mounted) return;
      
      if (result != null) {
        // 주문 성공 팝업 표시
        String displayPrice;
        String displayQuantity;
        String displayTotalAmount;
        
        if (widget.assetClass == 'crypto' && _selectedOrderType == '지정가') {
          displayPrice = _priceController.text;
          displayQuantity = originalQuantity; // 원본 수량 사용
          displayTotalAmount = ((double.tryParse(originalQuantity) ?? 0.0) * (double.tryParse(_priceController.text) ?? 0.0)).toStringAsFixed(2);
        } else if (widget.assetClass == 'crypto' && _selectedOrderType == '시장가') {
          displayPrice = '시장가';
          displayQuantity = (_marketOrderAmount / _currentMarketPrice).toStringAsFixed(9);
          displayTotalAmount = _marketOrderAmount.toStringAsFixed(2);
        } else {
          displayPrice = _price.toString();
          displayQuantity = _quantity.toString();
          displayTotalAmount = (_quantity * _price).toString();
        }
        
        _showOrderSuccessPopup(
          symbol: widget.symbol,
          orderType: _selectedOrderTab,
          orderMethod: _selectedOrderType,
          price: displayPrice,
          quantity: displayQuantity,
          totalAmount: displayTotalAmount,
          currency: widget.assetClass == 'crypto' ? 'USD' : '원',
        );
        
        setState(() {
          _selectedOrderTab = '내역';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 접수에 실패했습니다\n잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.chartRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = '주문 처리 중 오류가 발생했습니다';
      if (e.toString().contains('500')) {
        errorMessage = '서버에 일시적인 문제가 발생했습니다\n잠시 후 다시 시도해주세요';
      } else if (e.toString().contains('401')) {
        errorMessage = '인증이 필요합니다\n로그인을 다시 해주세요';
      } else if (e.toString().contains('403')) {
        errorMessage = '거래 권한이 없습니다\n계정 설정을 확인해주세요';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '요청 시간이 초과되었습니다\n네트워크를 확인해주세요';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.chartRed,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });
      }
    }
  }

  Future<void> _setMaxQuantity() async {
    try {
      final accountInfo = await StockApiService.getAlpacaAccount();
      
      if (accountInfo == null || _exchangeRate == null || _price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('매수 가능 금액을 확인할 수 없습니다'),
            backgroundColor: AppColors.chartRed,
          ),
        );
        return;
      }
      
      final buyingPowerUsd = double.tryParse(accountInfo['buyingPower']?.toString() ?? '0') ?? 0;
      final buyingPowerKrw = buyingPowerUsd * _exchangeRate!;
      final maxQuantity = (buyingPowerKrw / _price).floor();
      
      if (maxQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('매수 가능 금액이 부족합니다'),
            backgroundColor: AppColors.chartRed,
          ),
        );
        return;
      }
      
      setState(() {
        _quantity = maxQuantity;
        _quantityController.text = maxQuantity.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('최대 수량 계산 중 오류가 발생했습니다'),
          backgroundColor: AppColors.chartRed,
        ),
      );
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
              size: context.w(64),
              color: Color(0xFFF44336),
            ),
            SizedBox(height: context.h(16)),
            Text(
              _error!,
              style: AppFonts.b1Semibold.copyWith(color: Color(0xFFF44336)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(16)),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dividerPosition = screenWidth / 2; // 1:1 비율이므로 화면 중앙
    
    return Column(
      children: [
        // 체결강도 블록 (crypto만 표시)
        if (widget.assetClass == 'crypto') _buildExecutionStrength(),
        
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(9)),
                child: Row(
                  children: [
                    // 좌측 호가창
                    Expanded(
                      flex: 1,
                      child: widget.assetClass == 'crypto'
                          ? VerticalOrderBookWidget(
                              symbol: widget.symbol,
                              orderBook: _orderBook,
                              isLoading: _isLoadingOrderBook,
                              onRefresh: () async {
                                // WebSocket 재연결
                                await _webSocket?.disconnect();
                                await _loadOrderBook();
                              },
                            )
                          : UsStockOrderBookWidget(
                              symbol: widget.symbol,
                              onPriceSelected: (price) {
                                // 호가 터치 시 주문 폼의 가격 입력란에 반영 (USD)
                                _stockOrderFormKey.currentState?.updatePriceFromOrderBook(price);
                              },
                            ),
                    ),
                    SizedBox(width: context.w(14)),
                    // 우측 주문 폼
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - 
                                      MediaQuery.of(context).padding.top - 
                                      MediaQuery.of(context).padding.bottom - 
                                      (widget.assetClass == 'crypto' ? 100 : 0),
                          ),
                          child: IntrinsicHeight(
                            child: _buildOrderForm(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // divider
              Positioned(
                left: dividerPosition,
                top: 0,
                bottom: 0,
                child: Container(
                  width: context.w(1),
                  color: AppColors.gray100,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionStrength() {
    // 체결강도 계산 (매수량 대비 매도량 비율)
    double executionStrength = 50.0; // 기본값
    
    if (_orderBook != null && _orderBook!.bids.isNotEmpty && _orderBook!.asks.isNotEmpty) {
      final totalBidVolume = _orderBook!.bids.fold<double>(0, (sum, bid) => sum + bid.quantity);
      final totalAskVolume = _orderBook!.asks.fold<double>(0, (sum, ask) => sum + ask.quantity);
      final totalVolume = totalBidVolume + totalAskVolume;
      
      if (totalVolume > 0) {
        executionStrength = (totalBidVolume / totalVolume) * 100;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(8)),
      padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFD1E8F8), // #D1E8F8 배경색
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '체결 강도',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray600),
          ),
          Text(
            '${executionStrength.toStringAsFixed(2)}%',
            style: AppFonts.b2Semibold.copyWith(
              color: executionStrength > 50 ? AppColors.chartBlue : AppColors.chartRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm() {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 매수/매도/내역 탭
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Center(
                        child: _buildOrderTabButton('매수', _selectedOrderTab == '매수'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildOrderTabButton('매도', _selectedOrderTab == '매도'),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildOrderTabButton('내역', _selectedOrderTab == '내역'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(8)),
                Container(
                  width: double.infinity,
                  height: context.h(1),
                  color: AppColors.gray100,
                ),
              ],
            ),
            SizedBox(height: context.h(20)),
            
        // 내역 탭이면 주문 내역 표시, 아니면 주문 폼 표시
        if (_selectedOrderTab == '내역')
          _buildOrderHistoryContent()
        else if (widget.assetClass == 'crypto')
          CryptoOrderForm(
            symbol: widget.symbol,
            selectedOrderTab: _selectedOrderTab,
            stockDetail: _stockDetail,
            currentMarketPrice: _currentMarketPrice,
            onSubmit: _handleOrderSubmitFromForm,
            onSetMaxQuantity: _setMaxQuantity,
            isSubmitting: _isSubmittingOrder,
          )
        else
          StockOrderForm(
            key: _stockOrderFormKey,
            symbol: widget.symbol,
            selectedOrderTab: _selectedOrderTab,
            exchangeRate: _exchangeRate,
            tickSizeInKrw: _tickSizeInKrw,
            buyingPower: _buyingPower,
            positionQuantity: _positionQuantity,
            currentMarketPrice: _currentMarketPrice,
            onSubmit: _handleOrderSubmitFromForm,
            onSetMaxQuantity: _setMaxQuantity,
            isSubmitting: _isSubmittingOrder,
          ),
      ],
    );
  }
  
  // 주문 폼에서 호출되는 콜백
  Future<void> _handleOrderSubmitFromForm(
    String orderType,
    String orderMethod,
    String quantity,
    String? limitPrice,
    String apiSymbol,
  ) async {
    try {
      // 주문 확인 다이얼로그
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('주문 확인'),
          content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text('종목: ${widget.symbol}'),
              Text('구분: $orderType'),
              Text('주문타입: $orderMethod'),
              if (orderMethod == '시장가') ...[
                Text('수량: $quantity${widget.assetClass == 'crypto' ? '개' : '주'}'),
                Text('가격: 시장가'),
              ] else ...[
                Text('수량: $quantity${widget.assetClass == 'crypto' ? '개' : '주'}'),
                Text('가격: ${limitPrice ?? 'N/A'}${widget.assetClass == 'crypto' ? ' USD' : ' USD'}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('확인'),
                        ),
                      ],
                    ),
      );

      if (confirmed != true) return;

      // 로딩 상태 시작
                                      setState(() {
        _isSubmittingOrder = true;
      });

      // 주문 생성
      final orderTypeEnum = orderMethod == '시장가' ? OrderType.market : OrderType.limit;
      final timeInForce = widget.assetClass == 'crypto' ? TimeInForce.gtc : TimeInForce.day;
      
      final order = OrderRequest(
        symbol: apiSymbol,
        quantity: quantity,
        side: orderType == '매도' ? OrderSide.sell : OrderSide.buy,
        type: orderTypeEnum,
        timeInForce: timeInForce,
        limitPrice: limitPrice,
      );

      // 주문 요청 로그 출력
      print('=== 주문 요청 정보 ===');
      print('원본 심볼: ${widget.symbol}');
      print('API 심볼: $apiSymbol');
      print('수량: $quantity');
      print('방향: ${orderType == '매도' ? 'sell' : 'buy'}');
      print('타입: ${orderTypeEnum.name}');
      print('유효기간: ${timeInForce.name}');
      print('지정가: $limitPrice');
      print('주문 데이터: ${order.toJson()}');
      print('==================');

      final result = await OrderApiService.createOrder(order);
      
      if (!mounted) return;
      
      if (result != null) {
        // 주문 성공 팝업 표시
        final displayPrice = orderMethod == '시장가' ? '시장가' : (limitPrice ?? 'N/A');
        final displayQuantity = quantity;
        
        // 시장가 주문의 경우 marketOrder.currentPrice 또는 filledAvgPrice 확인
        String displayTotalAmount;
        if (orderMethod == '시장가') {
          // 1. marketOrder.currentPrice 확인
          final marketOrder = result['marketOrder'] as Map<String, dynamic>?;
          final currentPrice = marketOrder?['currentPrice'];
          
          // 2. filledAvgPrice 확인 (직접 응답에 있는 경우)
          final filledAvgPrice = result['filledAvgPrice'];
          
          // 3. limitOrder.totalAmount 확인 (시장가 주문이지만 totalAmount가 있는 경우)
          final limitOrder = result['limitOrder'] as Map<String, dynamic>?;
          final totalAmount = limitOrder?['totalAmount'];
          
          double? price;
          if (currentPrice != null) {
            price = double.tryParse(currentPrice.toString());
          } else if (filledAvgPrice != null) {
            price = double.tryParse(filledAvgPrice.toString());
          }
          
          if (price != null && price > 0) {
            // 체결 가격이 있으면 총액 계산
            final qty = double.tryParse(quantity) ?? 0.0;
            final totalUsd = price * qty;
            
            // 주식의 경우 환율 적용하여 원화로 표시
            if (widget.assetClass != 'crypto' && _exchangeRate != null) {
              final totalKrw = totalUsd * _exchangeRate!;
              displayTotalAmount = totalKrw.toStringAsFixed(0);
            } else {
              displayTotalAmount = totalUsd.toStringAsFixed(2);
            }
          } else if (totalAmount != null) {
            // totalAmount가 직접 있는 경우
            final total = double.tryParse(totalAmount.toString()) ?? 0.0;
            if (widget.assetClass != 'crypto' && _exchangeRate != null) {
              final totalKrw = total * _exchangeRate!;
              displayTotalAmount = totalKrw.toStringAsFixed(0);
            } else {
              displayTotalAmount = total.toStringAsFixed(2);
            }
          } else {
            // 체결 가격이 없으면 "체결 후 확인 가능" 표시
            displayTotalAmount = '체결 후 확인 가능';
          }
        } else {
          // 지정가 주문
          final qty = double.tryParse(quantity) ?? 0.0;
          final price = double.tryParse(limitPrice ?? '0') ?? 0.0;
          final total = qty * price;
          
          // 주식의 경우 환율 적용하여 원화로 표시
          if (widget.assetClass != 'crypto' && _exchangeRate != null) {
            final totalKrw = total * _exchangeRate!;
            displayTotalAmount = totalKrw.toStringAsFixed(0);
          } else {
            displayTotalAmount = total.toStringAsFixed(2);
          }
        }
        
        _showOrderSuccessPopup(
          symbol: widget.symbol,
          orderType: orderType,
          orderMethod: orderMethod,
          price: displayPrice,
          quantity: displayQuantity,
          totalAmount: displayTotalAmount,
          currency: widget.assetClass == 'crypto' ? 'USD' : '원',
        );
        
                                setState(() {
          _selectedOrderTab = '내역';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 접수에 실패했습니다\n잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.chartRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = '주문 처리 중 오류가 발생했습니다';
      if (e.toString().contains('500')) {
        errorMessage = '서버에 일시적인 문제가 발생했습니다\n잠시 후 다시 시도해주세요';
      } else if (e.toString().contains('401')) {
        errorMessage = '인증이 필요합니다\n로그인을 다시 해주세요';
      } else if (e.toString().contains('403')) {
        errorMessage = '거래 권한이 없습니다\n계정 설정을 확인해주세요';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '요청 시간이 초과되었습니다\n네트워크를 확인해주세요';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.chartRed,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOrder = false;
        });
      }
    }
  }
  

  Widget _buildOrderTabButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrderTab = text;
          
          // 내역 탭 선택 시 주문 내역 로드
          if (text == '내역') {
            _loadOrderHistory();
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 1.3,
              color: isSelected ? AppColors.gray900 : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.gray900 : AppColors.gray300,
            fontSize: 13,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            height: 1.31,
          ),
        ),
      ),
    );
  }
  
  // 주문 내역 컨텐츠
  Widget _buildOrderHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 드롭다운
        GestureDetector(
          onTap: () {
            _showFilterBottomSheet();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _historyFilter,
                style: AppFonts.b1Regular.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: context.w(4)),
              Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(16)),
        
        // 주문 내역 리스트
        if (_isLoadingHistory)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.h(40)),
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          )
        else if (_orderHistory.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.h(40)),
              child: Text(
                '주문 내역이 없습니다',
                style: AppFonts.b1Regular.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ),
          )
        else
          ...(_orderHistory.map((order) => _buildOrderHistoryItem(order))),
      ],
    );
  }
  
  // 필터 바텀시트
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.h(12)),
              Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: context.h(20)),
              _buildFilterOption('전체'),
              _buildFilterOption('매수'),
              _buildFilterOption('매도'),
              SizedBox(height: context.h(20)),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFilterOption(String label) {
    final isSelected = _historyFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _historyFilter = label;
        });
        _loadOrderHistory();
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.h(16), horizontal: context.w(24)),
        child: Text(
          label,
          style: AppFonts.b1Regular.copyWith(
            color: isSelected ? AppColors.primary : AppColors.gray900,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
  
  // 주문 내역 아이템
  Widget _buildOrderHistoryItem(OrderHistoryModel order) {
    return GestureDetector(
      onTap: () {
        // 주문 상세 페이지로 이동
        try {
          context.push('/order-detail/${order.orderId}');
        } catch (e) {
          logger.e('주문 상세 페이지 이동 실패: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('주문 상세를 열 수 없습니다'),
                backgroundColor: AppColors.chartRed,
              ),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: context.h(55),
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.all(context.w(8)),
        decoration: ShapeDecoration(
          color: const Color(0xFFF7F7F7), // Gray-30
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 (좌측)
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(
                color: const Color(0xFF7F7F7F), // Gray-600
                fontSize: 13,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                height: 1.23,
              ),
            ),
            SizedBox(height: context.h(4)),
            
            // 수량·가격과 상태 (같은 줄, 좌우 배치)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 수량과 가격 (좌측)
                Flexible(
                  child: Text(
                    _formatQuantityAndPrice(order),
                    style: TextStyle(
                      color: const Color(0xFF323232), // Gray-900
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      height: 1.23,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 상태 (우측)
                Text(
                  _getStatusLabel(order),
                  style: TextStyle(
                    color: const Color(0xFF7F7F7F), // Gray-600
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.23,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderSuccessPopup({
    required String symbol,
    required String orderType,
    required String orderMethod,
    required String price,
    required String quantity,
    required String totalAmount,
    required String currency,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.5),
            child: Stack(
              children: [
                // 팝업 컨테이너
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                        minHeight: 320,
                      ),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.w(20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 아이콘
                        Container(
                          width: context.w(50),
                          height: context.h(50),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: orderType == '매수' ? AppColors.chartRed : AppColors.chartBlue,
                            size: context.w(25),
                          ),
                        ),
                        SizedBox(height: context.h(16)),
                        // 성공 메시지
                        Text(
                          '$symbol $orderType 주문 요청 성공',
                          style: AppFonts.t1Bold.copyWith(
                            color: orderType == '매수' ? AppColors.chartRed : AppColors.chartBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.h(24)),
                        // 주문 상세 정보
                        Container(
                          padding: EdgeInsets.all(context.w(16)),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildOrderDetailRow(orderMethod == '시장가' ? '주문타입' : '지정가', orderMethod == '시장가' ? orderMethod : '$price$currency'),
                              SizedBox(height: 12),
                              _buildOrderDetailRow('수량', '$quantity${currency == '원' ? '주' : '개'}'),
                              SizedBox(height: 12),
                              _buildOrderDetailRow('총액', totalAmount == '체결 후 확인 가능' ? totalAmount : '$totalAmount$currency'),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // 확인 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: orderType == '매수' ? AppColors.chartRed : AppColors.chartBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '확인',
                                style: AppFonts.t1Bold.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.t1Bold.copyWith(
            color: AppColors.gray600,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppFonts.t1Bold.copyWith(
            color: AppColors.gray900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

