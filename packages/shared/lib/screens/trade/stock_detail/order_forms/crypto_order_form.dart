import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/stock_detail_model.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'dart:math' as math;

/// 암호화폐 주문 폼 위젯
class CryptoOrderForm extends StatefulWidget {
  final String symbol;
  final String selectedOrderTab; // '매수', '매도'
  final StockDetailModel? stockDetail;
  final double currentMarketPrice;
  final Function(String orderType, String orderMethod, String quantity, String? limitPrice, String apiSymbol) onSubmit;
  final Function() onSetMaxQuantity;
  final bool isSubmitting;

  const CryptoOrderForm({
    super.key,
    required this.symbol,
    required this.selectedOrderTab,
    this.stockDetail,
    required this.currentMarketPrice,
    required this.onSubmit,
    required this.onSetMaxQuantity,
    required this.isSubmitting,
  });

  @override
  State<CryptoOrderForm> createState() => _CryptoOrderFormState();
}

class _CryptoOrderFormState extends State<CryptoOrderForm> {
  String _selectedOrderType = '지정가'; // '지정가', '시장가'
  
  // 수량 관련
  double _quantity = 0.0;
  double _marketOrderAmount = 1.0; // 시장가 주문용 USDT 금액
  double _price = 0.0;
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _marketAmountController = TextEditingController();
  
  // 포커스 노드
  final FocusNode _quantityFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _marketAmountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _marketAmountController.text = '1.0';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _marketAmountController.dispose();
    _quantityFocusNode.dispose();
    _priceFocusNode.dispose();
    _marketAmountFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // 입력 검증
    if (_selectedOrderType == '지정가') {
      if (_quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수량을 입력해주세요'),
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
    } else {
      // 시장가
      if (_marketOrderAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('USDT 금액을 입력해주세요'),
            backgroundColor: AppColors.loss,
          ),
        );
        return;
      }
    }

    // 주문 생성
    String? limitPrice;
    String quantity;
    String apiSymbol = widget.symbol;
    
    if (_selectedOrderType == '시장가') {
      // 시장가 정보 검증
      if (widget.currentMarketPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('시장가 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요'),
            backgroundColor: AppColors.loss,
          ),
        );
        return;
      }
      
      // 암호화폐 시장가: USDT 금액 기반으로 수량 계산
      final rules = widget.stockDetail?.toOrderRules() ?? OrderRules.crypto(
        minOrderSize: 0.000223249,
        minTradeIncrement: 0.000000001,
        priceIncrement: 0.01,
      );
      final estimatedQty = _marketOrderAmount / widget.currentMarketPrice;
      final minQty = rules.minPassingQtyAtPrice(widget.currentMarketPrice);
      final finalQty = estimatedQty > minQty ? estimatedQty : minQty;
      quantity = finalQty.toStringAsFixed(9);
      limitPrice = null;
    } else {
      // 암호화폐 지정가: 동적 규칙 적용
      final rules = widget.stockDetail?.toOrderRules() ?? OrderRules.crypto(
        minOrderSize: 0.000223249,
        minTradeIncrement: 0.000000001,
        priceIncrement: 0.01,
      );
      
      // 가격 정규화
      final normalizedPrice = rules.normalizePrice(_price);
      
      // 수량 정규화 및 최소 체결금액 보장
      final normalizedQty = rules.normalizeQuantity(_quantity);
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
            content: Text('주문 검증 실패: ${validation.errors.join(', ')}\n최소 주문 수량: ${rules.minOrderSize}개'),
            backgroundColor: AppColors.loss,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }
    
    // 심볼 형식 변환 (BTCUSDT -> BTC/USD, ETH/USDT -> ETH/USD)
    if (apiSymbol.contains('USDT')) {
      apiSymbol = apiSymbol.replaceAll('USDT', 'USD');
    } else if (apiSymbol.contains('USDC')) {
      apiSymbol = apiSymbol.replaceAll('USDC', 'USD');
    }
    
    if (!apiSymbol.contains('/') && apiSymbol.endsWith('USD')) {
      final baseCurrency = apiSymbol.substring(0, apiSymbol.length - 3);
      apiSymbol = '$baseCurrency/USD';
    }
    
    widget.onSubmit(
      widget.selectedOrderTab,
      _selectedOrderType,
      quantity,
      limitPrice,
      apiSymbol,
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 주문 타입 선택
          SizedBox(
            width: context.w(188),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOrderType = _selectedOrderType == '지정가' ? '시장가' : '지정가';
                });
              },
              child: Text(
                '$_selectedOrderType ▾',
                textAlign: TextAlign.right,
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
            textAlign: TextAlign.right,
            style: AppFonts.btn2.copyWith(
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: context.h(9)),
          
          // 수량 입력 필드
          Container(
            width: context.w(188),
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
                                controller: _selectedOrderType == '시장가' 
                                    ? _marketAmountController 
                                    : _quantityController,
                                focusNode: _selectedOrderType == '시장가' 
                                    ? _marketAmountFocusNode 
                                    : _quantityFocusNode,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                style: AppFonts.b1Semibold.copyWith(
                                  color: AppColors.gray900,
                                ),
                                decoration: InputDecoration(
                                  hintText: _selectedOrderType == '시장가' ? 'USDT 금액' : '수량',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  if (_selectedOrderType == '시장가') {
                                    final amount = double.tryParse(value) ?? 1.0;
                                    setState(() {
                                      _marketOrderAmount = amount;
                                    });
                                  } else {
                                    final quantity = double.tryParse(value) ?? 0.0;
                                    setState(() {
                                      _quantity = quantity;
                                    });
                                  }
                                },
                              ),
                            ),
                            Text(
                              _selectedOrderType == '시장가' ? 'USDT' : '개',
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
          
          // 가격 입력 필드
          Container(
            width: context.w(188),
            decoration: ShapeDecoration(
              color: _selectedOrderType == '시장가' ? AppColors.gray100 : AppColors.gray50,
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
                        child: TextField(
                          controller: _priceController,
                          focusNode: _priceFocusNode,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          enabled: _selectedOrderType != '시장가',
                          style: AppFonts.b1Semibold.copyWith(
                            color: _selectedOrderType == '시장가' ? AppColors.gray400 : AppColors.gray900,
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
                      SizedBox(width: context.w(4)),
                      Text(
                        'USD',
                        style: AppFonts.b1Regular.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: (availableHeight * 0.05).clamp(10.0, 20.0)),
          
          // 총액
          Padding(
            padding: EdgeInsets.only(left: context.w(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      ? '${_marketOrderAmount.toStringAsFixed(2)} USDT' 
                      : '${((widget.stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizeQuantity(_quantity) * (widget.stockDetail?.toOrderRules() ?? OrderRules.crypto(minOrderSize: 0.000223249, minTradeIncrement: 0.000000001, priceIncrement: 0.01)).normalizePrice(_price)).toStringAsFixed(2)} USD',
                  style: AppFonts.t1Bold.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: (availableHeight * 0.03).clamp(8.0, 16.0)),
          
          // 매수/매도 버튼
          GestureDetector(
            onTap: widget.isSubmitting ? null : _handleSubmit,
            child: Container(
              width: context.w(188),
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

