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
import 'package:qbit_shared/widgets/trade/vertical_orderbook_widget.dart';
import 'package:qbit_services/models/stock_detail_model.dart';

class StockOrderTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;

  const StockOrderTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
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
  
  // 환율 관련
  double? _exchangeRate;
  double? _tickSizeInKrw;
  
  // 주문 제출 상태
  bool _isSubmittingOrder = false;
  
  // 현재 시장 가격 (시장가 주문용)
  double _currentMarketPrice = 0.0;
  
  // 종목 상세 정보
  StockDetailModel? _stockDetail;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '';
    _priceController.text = '';
    _marketAmountController.text = '1.0';
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _marketAmountController.dispose();
    _webSocket?.disconnect();
    _webSocket?.dispose();
    super.dispose();
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
  
  /// 현재 시장 가격 로드
  Future<void> _loadCurrentMarketPrice() async {
    try {
      if (widget.assetClass == 'crypto') {
        // 암호화폐: 호가창에서 현재 가격 가져오기
        if (_orderBook != null && _orderBook!.bids.isNotEmpty && _orderBook!.asks.isNotEmpty) {
          final bestBid = _orderBook!.bids.first.price;
          final bestAsk = _orderBook!.asks.first.price;
          _currentMarketPrice = (bestBid + bestAsk) / 2; // 중간가격
        }
      } else {
        // 주식: 현재 가격을 KRW로 설정 (환율 적용)
        _currentMarketPrice = _price;
      }
    } catch (error) {
      print('현재 시장 가격 로드 실패: $error');
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
        orderBook = await StockApiService.getCryptoOrderBook(widget.symbol)
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
        _webSocket = CryptoOrderBookWebSocket();
        await _webSocket!.connect(widget.symbol);
        
        // WebSocket 스트림 구독
        _webSocket!.orderBookStream.listen((updatedOrderBook) {
          if (mounted) {
            setState(() {
              _orderBook = updatedOrderBook;
            });
          }
        });
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
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }
    
    // 지정가 주문일 때만 가격 검증
    if (_selectedOrderType == '지정가' && _price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가격을 입력해주세요'),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }
    
    // 시장가 주문일 때 USDT 금액 검증 (암호화폐만)
    if (_selectedOrderType == '시장가' && widget.assetClass == 'crypto' && _marketOrderAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('USDT 금액을 입력해주세요'),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }
    
    // 환율 확인
    if (_exchangeRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요'),
          backgroundColor: AppColors.loss,
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
          
          // 유효성 검사
          final validation = rules.validateOrder(
            quantity: finalQty,
            price: normalizedPrice,
            isMarketOrder: false,
          );
          
          if (!validation.isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('주문 검증 실패: ${validation.errors.join(', ')}'),
                backgroundColor: AppColors.loss,
                duration: Duration(seconds: 3),
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

      // 주문 요청 로그 출력
      print('=== 주문 요청 정보 ===');
      print('원본 심볼: ${widget.symbol}');
      print('API 심볼: $apiSymbol');
      print('수량: $quantity');
      print('방향: ${_selectedOrderTab == '매도' ? 'sell' : 'buy'}');
      print('타입: ${orderType.name}');
      print('유효기간: ${timeInForce.name}');
      print('지정가: $limitPrice');
      print('주문 데이터: ${order.toJson()}');
      print('==================');

      final result = await OrderApiService.createOrder(order);
      
      if (!mounted) return;
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문이 접수되었습니다\n주문 ID: ${result['orderId'] ?? 'N/A'}'),
            backgroundColor: AppColors.profit,
            duration: Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _selectedOrderTab = '내역';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 접수에 실패했습니다\n잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.loss,
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
          backgroundColor: AppColors.loss,
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
            backgroundColor: AppColors.loss,
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
            backgroundColor: AppColors.loss,
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
          backgroundColor: AppColors.loss,
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
                padding: const EdgeInsets.symmetric(horizontal: 9.0),
                child: widget.assetClass == 'crypto' 
                  ? Row(
                      children: [
                        // 암호화폐: 좌측 호가창 + 우측 주문 폼
                        Expanded(
                          flex: 1,
                          child: VerticalOrderBookWidget(
                            symbol: widget.symbol,
                            orderBook: _orderBook,
                            isLoading: _isLoadingOrderBook,
                            onRefresh: () async {
                              // WebSocket 재연결
                              await _webSocket?.disconnect();
                              await _loadOrderBook();
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 1,
                          child: _buildOrderForm(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: _buildOrderForm(),
                        ),
                      ],
                    ),
              ),
              // divider
              if (widget.assetClass == 'crypto')
                Positioned(
                  left: dividerPosition,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              color: executionStrength > 50 ? AppColors.profit : AppColors.loss,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm() {
    final isCryptoSymbol = widget.assetClass == 'crypto';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isCryptoSymbol ? CrossAxisAlignment.end : CrossAxisAlignment.center,
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
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.gray100,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 주문 타입 선택 (암호화폐만 시장가 옵션 제공)
            SizedBox(
              width: isCryptoSymbol ? 188 : double.infinity,
              child: widget.assetClass == 'crypto' 
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOrderType = _selectedOrderType == '지정가' ? '시장가' : '지정가';
                      });
                    },
                    child: Text(
                      '$_selectedOrderType ▾',
                      textAlign: isCryptoSymbol ? TextAlign.right : TextAlign.center,
                      style: AppFonts.b2Semibold.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  )
                : Text(
                    '지정가 ▾',
                    textAlign: isCryptoSymbol ? TextAlign.right : TextAlign.center,
                    style: AppFonts.b2Semibold.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
            ),
            const SizedBox(height: 2),
            
            // 주문가능 금액
            Text(
              '주문가능금액',
              textAlign: isCryptoSymbol ? TextAlign.right : TextAlign.center,
              style: AppFonts.btn2.copyWith(
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 9),
            
            // 수량 입력 필드
            Container(
              width: isCryptoSymbol ? 188 : double.infinity,
              height: 110,
              decoration: ShapeDecoration(
                color: AppColors.gray50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '수량',
                      style: AppFonts.b2Regular.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: widget.assetClass == 'crypto' && _selectedOrderType == '시장가' 
                                    ? _marketAmountController 
                                    : _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: AppFonts.b1Regular.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget.assetClass == 'crypto' && _selectedOrderType == '시장가' ? 'USDT 금액' : '수량',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    if (widget.assetClass == 'crypto' && _selectedOrderType == '시장가') {
                                      final amount = double.tryParse(value) ?? 1.0;
                                      setState(() {
                                        _marketOrderAmount = amount;
                                      });
                                    } else {
                                      final quantity = int.tryParse(value) ?? 1;
                                      setState(() {
                                        _quantity = quantity;
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text(
                                widget.assetClass == 'crypto' 
                                  ? (_selectedOrderType == '시장가' ? 'USDT' : '개')
                                  : '주',
                                style: AppFonts.b1Regular.copyWith(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _setMaxQuantity,
                          child: Text(
                            '최대 ▾',
                            style: AppFonts.b2Semibold.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            
            // 가격 입력 필드
            Container(
              width: isCryptoSymbol ? 188 : double.infinity,
              height: 110,
              decoration: ShapeDecoration(
                color: _selectedOrderType == '시장가' ? AppColors.gray100 : AppColors.gray50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '가격',
                      style: AppFonts.b2Regular.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  enabled: _selectedOrderType != '시장가',
                                  style: AppFonts.b1Regular.copyWith(
                                    color: _selectedOrderType == '시장가' ? AppColors.gray400 : AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _selectedOrderType == '시장가' ? '시장가' : '가격',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    if (_selectedOrderType != '시장가') {
                                      final price = double.tryParse(value) ?? 0.0;
                                      setState(() {
                                        _price = price;
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text(
                                widget.assetClass == 'crypto' ? 'USD' : '원',
                                style: AppFonts.b1Regular.copyWith(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final tickSize = _tickSizeInKrw ?? 13.0;
                                setState(() {
                                  _price = (_price - tickSize).clamp(0, double.infinity);
                                  _priceController.text = _price.toStringAsFixed(0);
                                });
                              },
                              child: Text(
                                '−',
                                style: AppFonts.b2Semibold.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final tickSize = _tickSizeInKrw ?? 13.0;
                                setState(() {
                                  _price = _price + tickSize;
                                  _priceController.text = _price.toStringAsFixed(0);
                                });
                              },
                              child: Text(
                                '+',
                                style: AppFonts.b2Semibold.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
            
            // 총액
            Padding(
              padding: EdgeInsets.only(left: isCryptoSymbol ? 8 : 0),
              child: Column(
                crossAxisAlignment: isCryptoSymbol ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Text(
                    '총액',
                    style: AppFonts.b2Regular.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.assetClass == 'crypto' 
                      ? (_selectedOrderType == '시장가' 
                          ? '${_marketOrderAmount.toStringAsFixed(2)} USDT' 
                          : '${((_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizeQuantity(_quantity.toDouble()) * (_stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizePrice(_price)).toStringAsFixed(2)} USD')
                      : '${(_quantity * _price).toStringAsFixed(0)}원',
                    style: AppFonts.t1Bold.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w600,
                      height: 1.20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 매수/매도 버튼
            GestureDetector(
              onTap: _isSubmittingOrder ? null : _handleOrderSubmit,
              child: Container(
                width: isCryptoSymbol ? 188 : double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  color: _selectedOrderTab == '매도' ? AppColors.loss : AppColors.profit,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _isSubmittingOrder
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedOrderTab == '매도' ? '매도' : '매수',
                          style: AppFonts.t1Bold.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.20,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildOrderTabButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrderTab = text;
        });
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? AppColors.gray900 : AppColors.gray300,
          fontSize: 16,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          height: 1.40,
        ),
      ),
    );
  }
}

