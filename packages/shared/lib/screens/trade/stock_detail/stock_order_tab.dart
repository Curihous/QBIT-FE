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
import 'package:qbit_shared/widgets/trade/orderbook_widget.dart';

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
  
  // 주문 관련 상태
  int _quantity = 1;
  double _price = 0.0;
  String _selectedOrderTab = '매수'; // '매수', '매도', '내역'
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // 환율 관련
  double? _exchangeRate;
  double? _tickSizeInKrw;
  
  // 주문 제출 상태
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '';
    _priceController.text = '';
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
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

  Future<void> _loadOrderBook() async {
    setState(() {
      _isLoadingOrderBook = true;
      _isLoading = true;
    });

    try {
      final orderBook = await StockApiService.getCryptoOrderBook(widget.symbol)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
      if (mounted) {
        setState(() {
          _orderBook = orderBook;
          _isLoadingOrderBook = false;
          _isLoading = false;
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
    
    if (_price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가격을 입력해주세요'),
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
              Text('수량: $_quantity주'),
              Text('가격: ${_price.toStringAsFixed(0)}원'),
              Text('총액: ${(_quantity * _price).toStringAsFixed(0)}원'),
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

      // 주문 생성 (가격을 USD로 변환)
      final exchangeRate = _exchangeRate ?? 1300.0;
      final priceInUsd = _price / exchangeRate;
      final limitPriceInUsd = priceInUsd.toStringAsFixed(2);
      
      final order = OrderRequest(
        symbol: widget.symbol,
        quantity: _quantity.toString(),
        side: _selectedOrderTab == '매도' ? OrderSide.sell : OrderSide.buy,
        type: OrderType.limit,
        timeInForce: TimeInForce.day,
        limitPrice: limitPriceInUsd,
      );

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
            content: Text('주문 접수에 실패했습니다'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: AppColors.loss,
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

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
          child: widget.assetClass == 'crypto' 
            ? Row(
                children: [
                  // 암호화폐: 좌측 호가창 + 우측 주문 폼
                  Expanded(
                    flex: 40,
                    child: OrderBookWidget(
                      symbol: widget.symbol,
                      orderBook: _orderBook,
                      isLoading: _isLoadingOrderBook,
                      onRefresh: _loadOrderBook,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const SizedBox(width: 1.3),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 60,
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
        // 세로선 (암호화폐일 때만)
        if (widget.assetClass == 'crypto')
          Positioned(
            left: MediaQuery.of(context).size.width * 0.45,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.3,
              color: AppColors.gray100,
            ),
          ),
      ],
    );
  }

  Widget _buildOrderForm() {
    final isCryptoSymbol = widget.assetClass == 'crypto';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: SingleChildScrollView(
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
            
            // 지정가 드롭다운
            SizedBox(
              width: isCryptoSymbol ? 188 : double.infinity,
              child: Text(
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
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: AppFonts.b1Regular.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '수량',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    final quantity = int.tryParse(value) ?? 1;
                                    setState(() {
                                      _quantity = quantity;
                                    });
                                  },
                                ),
                              ),
                              Text(
                                '주',
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
                color: AppColors.gray50,
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
                                  style: AppFonts.b1Regular.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '가격',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    final price = double.tryParse(value) ?? 0.0;
                                    setState(() {
                                      _price = price;
                                    });
                                  },
                                ),
                              ),
                              Text(
                                '원',
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
                    '${(_quantity * _price).toStringAsFixed(0)}원',
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

