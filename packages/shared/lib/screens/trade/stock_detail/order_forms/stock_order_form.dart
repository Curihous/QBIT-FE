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
  final Function(String orderType, String orderMethod, String quantity, String? limitPrice, String apiSymbol) onSubmit;
  final Function() onSetMaxQuantity;
  final bool isSubmitting;

  const StockOrderForm({
    super.key,
    required this.symbol,
    required this.selectedOrderTab,
    this.exchangeRate,
    this.tickSizeInKrw,
    required this.onSubmit,
    required this.onSetMaxQuantity,
    required this.isSubmitting,
  });

  @override
  State<StockOrderForm> createState() => _StockOrderFormState();
}

class _StockOrderFormState extends State<StockOrderForm> {
  String _selectedOrderType = '지정가'; // '지정가', '시장가'
  int _quantity = 1;
  double _price = 0.0;
  
  // 통화 전환 상태
  bool _isShowingKRW = true; // true: 원화, false: 달러
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // 포커스 노드
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityController.text = '';
    _priceController.text = '';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
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
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }
    
    // 지정가 주문일 때만 가격 검증
    if (_selectedOrderType == '지정가') {
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
      if (widget.exchangeRate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.loss,
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
      // 지정가 주문: KRW를 USD로 변환
      final exchangeRate = widget.exchangeRate ?? 1300.0;
      final priceInUsd = _price / exchangeRate;
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
                textAlign: TextAlign.center,
                style: AppFonts.b2Semibold.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(2)),
          
          // 주문가능 금액
          Text(
            '주문가능금액',
            textAlign: TextAlign.center,
            style: AppFonts.btn2.copyWith(
              color: AppColors.gray900,
            ),
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
                    style: AppFonts.b2Regular.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
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
                        onTap: widget.onSetMaxQuantity,
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
              padding: EdgeInsets.symmetric(horizontal: context.w(22), vertical: context.h(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가격',
                    style: AppFonts.b2Regular.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                focusNode: _priceFocusNode,
                                keyboardType: TextInputType.number,
                                style: AppFonts.b1Semibold.copyWith(
                                  color: AppColors.gray900,
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
                            SizedBox(width: context.w(4)),
                            // 통화 토글 버튼
                            GestureDetector(
                              onTap: _toggleCurrency,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(8),
                                  vertical: context.h(4),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w(6),
                                        vertical: context.h(2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isShowingKRW ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        '원',
                                        style: AppFonts.b2Semibold.copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.w(2)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.w(6),
                                        vertical: context.h(2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_isShowingKRW ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        r'$',
                                        style: AppFonts.b2Semibold.copyWith(
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
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
                              style: AppFonts.b2Semibold.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                          SizedBox(width: context.w(8)),
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
          SizedBox(height: (availableHeight * 0.05).clamp(10.0, 20.0)),
          
          // 총액
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '총액',
                style: AppFonts.b2Regular.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              SizedBox(height: context.h(8)),
              Text(
                _selectedOrderType == '시장가' 
                    ? '시장가' 
                    : '${(_quantity * _price).toStringAsFixed(0)}원',
                style: AppFonts.t1Bold.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: (availableHeight * 0.03).clamp(8.0, 16.0)),
          
          // 매수/매도 버튼
          GestureDetector(
            onTap: widget.isSubmitting ? null : _handleSubmit,
            child: Container(
              width: double.infinity,
              height: (availableHeight * 0.06).clamp(40.0, 50.0),
              decoration: BoxDecoration(
                color: widget.selectedOrderTab == '매도' ? AppColors.loss : AppColors.profit,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: widget.isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.selectedOrderTab == '매도' ? '매도' : '매수',
                        style: AppFonts.t1Bold.copyWith(
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

