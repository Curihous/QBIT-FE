import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

/// 주식 주문 폼 위젯
class StockOrderForm extends StatefulWidget {
  final String symbol;
  final String selectedOrderTab; // '매수', '매도'
  final double? exchangeRate;
  final double? tickSizeInKrw;
  final double? buyingPower; // 매수 가능 금액 (USD)
  final double? positionQuantity; // 보유 수량 (주)
  final double? currentMarketPrice; // 현재 시장 가격 (USD)
  final Function(String orderType, String orderMethod, String quantity, String? limitPrice, String apiSymbol) onSubmit;
  final Function() onSetMaxQuantity;
  final String assetClass;
  final bool isSubmitting;

  const StockOrderForm({
    super.key,
    required this.symbol,
    required this.selectedOrderTab,
    this.assetClass = 'us_stock',
    this.exchangeRate,
    this.tickSizeInKrw,
    this.buyingPower,
    this.positionQuantity,
    this.currentMarketPrice,
    required this.onSubmit,
    required this.onSetMaxQuantity,
    required this.isSubmitting,
  });

  @override
  State<StockOrderForm> createState() => StockOrderFormState();
}

class StockOrderFormState extends State<StockOrderForm> {
  String _selectedOrderType = '지정가'; // '지정가', '시장가'
  double _quantity = 1.0;
  double _price = 0.0;
  
  // 통화 전환 상태 (미국 주식 폼에서는 기본 USD 사용)
  bool _isShowingKRW = false; // true: 원화, false: 달러
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityController.text = '';
    _priceController.text = '';
  }
  
  /// 호가창에서 선택한 가격으로 업데이트 (USD)
  void updatePriceFromOrderBook(double priceUsd) {
    setState(() {
      _price = priceUsd;
      _priceController.text = priceUsd.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  /// 총액 계산 메서드
  String _calculateTotalAmount() {
    if (_selectedOrderType == '시장가') {
      // 시장가일 때는 현재 시장 가격 기준으로 계산
      if (widget.currentMarketPrice != null && widget.currentMarketPrice! > 0) {
        return (_quantity * widget.currentMarketPrice!).toStringAsFixed(2);
      }
      // 시장 가격이 없을 때는 명확한 메시지 표시
      return _quantity > 0 ? '시장가(가격 없음)' : '0.00';
    } else {
      // 지정가일 때는 입력한 가격 기준으로 계산
      if (_price > 0 && _quantity > 0) {
        return (_price * _quantity).toStringAsFixed(2);
      }
      return '0.00';
    }
  }

  /// 통화 전환 메서드
  Future<void> _toggleCurrency() async {
    if (widget.exchangeRate == null) return;
    
    final rate = widget.exchangeRate!;
    
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

  void _handleSubmit() {
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
    
    // 주문 타입별 가격 검증
    if (_selectedOrderType == '지정가') {
      if (_price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가격을 입력해주세요'),
            backgroundColor: AppColors.chartRed,
          ),
        );
        return;
      }
      
      // 환율 확인
      if (widget.exchangeRate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.chartRed,
          ),
        );
        return;
      }
    } else if (_selectedOrderType == '시장가') {
      // 시장가 주문 시 현재 시장 가격 확인
      if (widget.currentMarketPrice == null || widget.currentMarketPrice! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시장 가격 정보를 불러올 수 없습니다. 잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.chartRed,
          ),
        );
        return;
      }
    }

    String? limitPrice;
    final quantity = _quantity.toString();
    
    if (_selectedOrderType == '시장가') {
      // 시장가 주문: limitPrice는 null
      limitPrice = null;
    } else {
      // 지정가 주문: 통화에 따라 적절히 변환
      final exchangeRate = widget.exchangeRate ?? 1300.0;
      final priceInKrw = _isShowingKRW ? _price : (_price * exchangeRate);
      final priceInUsd = _isShowingKRW ? (_price / exchangeRate) : _price;
      
      // API는 USD를 기대하므로 USD로 변환
      limitPrice = priceInUsd.toStringAsFixed(2);
    }
    
    widget.onSubmit(
      widget.selectedOrderTab,
      _selectedOrderType,
      quantity,
      limitPrice,
      widget.symbol,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 300;
    
    return Container(
      padding: EdgeInsets.fromLTRB(context.w(8), context.h(16), context.w(8), context.h(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 주문 타입 선택
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOrderType = _selectedOrderType == '지정가' ? '시장가' : '지정가';
                });
              },
              child: Text(
                '$_selectedOrderType ▾',
                textAlign: TextAlign.right,
                style: AppFonts.c1.copyWith(
                  color: AppColors.gray900,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.31,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(9)),
          
          // 주문가능 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '주문가능(USD)',
                style: AppFonts.c1.copyWith(
                  color: AppColors.gray600,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.23,
                ),
              ),
              Text(
                widget.buyingPower != null 
                    ? widget.buyingPower!.toStringAsFixed(2)
                    : '-',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.21,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(9)),
          
          // 수량 입력 필드
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: AppColors.gray50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(22), vertical: context.h(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '수량',
                    style: AppFonts.c1.copyWith(
                      color: AppColors.gray600,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.23,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                focusNode: _quantityFocusNode,
                                keyboardType: TextInputType.number,
                                style: AppFonts.b1Semibold.copyWith(
                                  color: AppColors.gray900,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: AppFonts.b1Semibold.copyWith(
                                    color: AppColors.gray400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final quantity = double.tryParse(value) ?? 0.0;
                                  setState(() {
                                    _quantity = quantity;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSetMaxQuantity,
                        child: Text(
                          '최대',
                          textAlign: TextAlign.right,
                          style: AppFonts.c1.copyWith(
                            color: AppColors.gray400,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.23,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.h(9)),
          
          // 가격 입력 필드 (시장가일 때는 숨김)
          if (_selectedOrderType == '지정가')
          Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: AppColors.gray50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(22), vertical: context.h(14)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가격(USD)',
                        style: AppFonts.c1.copyWith(
                          color: AppColors.gray600,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.23,
                        ),
                      ),
                      SizedBox(height: context.h(9)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              focusNode: _priceFocusNode,
                              keyboardType: TextInputType.number,
                              style: AppFonts.b1Semibold.copyWith(
                                color: AppColors.gray900,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
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
                          SizedBox(width: context.w(12)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final tickSize = !_isShowingKRW 
                                      ? ((widget.tickSizeInKrw ?? 13.0) / (widget.exchangeRate ?? 1300.0)) 
                                      : (widget.tickSizeInKrw ?? 13.0);
                                  setState(() {
                                    _price = (_price - tickSize).clamp(0, double.infinity);
                                    _priceController.text = !_isShowingKRW
                                        ? _price.toStringAsFixed(2)
                                        : _price.toStringAsFixed(0);
                                  });
                                },
                                child: Text(
                                  '−',
                                  style: AppFonts.c1.copyWith(
                                    color: AppColors.gray600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.31,
                                  ),
                                ),
                              ),
                              SizedBox(width: context.w(16)),
                              GestureDetector(
                                onTap: () {
                                  final tickSize = !_isShowingKRW 
                                      ? ((widget.tickSizeInKrw ?? 13.0) / (widget.exchangeRate ?? 1300.0)) 
                                      : (widget.tickSizeInKrw ?? 13.0);
                                  setState(() {
                                    _price = _price + tickSize;
                                    _priceController.text = !_isShowingKRW
                                        ? _price.toStringAsFixed(2)
                                        : _price.toStringAsFixed(0);
                                  });
                                },
                                child: Text(
                                  '+',
                                  style: AppFonts.c1.copyWith(
                                    color: AppColors.gray600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.31,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.h(60)),
          
          // 총액
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '총액(USD)',
                style: AppFonts.c1.copyWith(
                  color: AppColors.gray600,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.23,
                ),
              ),
              SizedBox(height: context.h(8)),
              Text(
                _calculateTotalAmount(),
                style: AppFonts.t1Bold.copyWith(
                  color: AppColors.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          
          // 매수/매도 버튼
          Builder(
            builder: (context) {
              // 시장가 주문 시 가격이 없으면 버튼 비활성화
              final isMarketOrderWithoutPrice = _selectedOrderType == '시장가' &&
                  (widget.currentMarketPrice == null || widget.currentMarketPrice! <= 0);
              final isButtonDisabled = widget.isSubmitting || isMarketOrderWithoutPrice;
              
              return GestureDetector(
                onTap: isButtonDisabled ? null : _handleSubmit,
                child: Container(
                  width: double.infinity,
                  height: context.h(45),
                  decoration: BoxDecoration(
                    color: isButtonDisabled
                        ? AppColors.gray300
                        : (widget.selectedOrderTab == '매도' ? AppColors.chartRed : AppColors.chartBlue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: widget.isSubmitting
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.selectedOrderTab == '매도' ? '매도' : '매수',
                            style: AppFonts.t1Bold.copyWith(
                              color: AppColors.gray0,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

