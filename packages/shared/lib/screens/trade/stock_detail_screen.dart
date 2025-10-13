import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_services/api/exchange_rate_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_services/auth/alpaca_auth_service.dart';
import 'package:qbit_shared/widgets/order/order_bottom_sheet.dart';

// 종목 상세 화면
class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  StockModel? _stockDetail;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0; // 0: 차트, 1: 호가, 2: 주문, 3: 시세
  int _selectedTimeframeIndex = 1; // 0: 30m, 1: 1h, 2: 4h, 3: 1d, 4: 기타
  
  // 주문 관련 상태
  int _quantity = 1; // 기본 수량 1주
  double _price = 12030.0; // TODO: 현재 체결가로 초기화 (API 연동 후)
  String _orderType = '지정가';
  String _selectedOrderTab = '매수'; // '매수', '매도', '내역'
  
  // 입력 필드 컨트롤러
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // 환율 관련
  double? _exchangeRate;
  double? _tickSizeInKrw;

  @override
  void initState() {
    super.initState();
    print('StockDetailScreen 초기화: ${widget.symbol} - ${widget.name}');
    // 초기값 설정
    _quantity = 1; // 기본 수량 1주
    _price = 0.0; // 기본 가격 (표시하지 않음)
    
    // 컨트롤러 초기화 (빈 값으로 시작)
    _quantityController.text = '';
    _priceController.text = '';
    
    _loadExchangeRateAndStockDetail();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadExchangeRateAndStockDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 환율 로드
      _exchangeRate = await ExchangeRateApiService.getUsdToKrwRate();
      _tickSizeInKrw = await ExchangeRateApiService.getTickSizeInKrw();
      
      print('환율 로드: $_exchangeRate KRW/USD');
      print('틱 사이즈: $_tickSizeInKrw KRW');

      // 주식 상세 정보 로드
      final stockDetail = await StockApiService.getStockDetail(widget.symbol);
      
      if (stockDetail != null) {
        setState(() {
          _stockDetail = stockDetail;
          _isLoading = false;
        });
        
        // 가격은 사용자가 직접 입력하도록 함 (자동 설정하지 않음)
        // _price는 이미 0.0으로 초기화되어 있음
      } else {
        setState(() {
          _error = '종목 정보를 불러올 수 없습니다';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = '오류가 발생했습니다: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOrderSubmit() async {
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
              Text('구분: ${_selectedOrderTab}'),
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

      // 주문 생성 (가격을 USD로 변환)
      final exchangeRate = _exchangeRate ?? 1300.0; // 기본 환율
      final priceInUsd = _price / exchangeRate;
      final limitPriceInUsd = priceInUsd.toStringAsFixed(2);
      
      final order = OrderModel(
        symbol: widget.symbol,
        quantity: _quantity.toString(),
        side: _selectedOrderTab == '매도' ? 'sell' : 'buy',
        type: 'limit', // 지정가 주문
        timeInForce: 'day',
        limitPrice: limitPriceInUsd,
      );

      final result = await OrderApiService.createOrder(order);
      
      if (result != null) {
        // 주문 성공
        print('주문 접수 성공! 주문 ID: ${result['id']}');
        print('주문 상태: ${result['status']}');
        print('전체 응답: $result');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문이 접수되었습니다\n주문 ID: ${result['id'] ?? 'N/A'}'),
            backgroundColor: AppColors.profit,
            duration: Duration(seconds: 5),
          ),
        );
        
        // 주문 내역 탭으로 이동
        setState(() {
          _selectedOrderTab = '내역';
        });
      } else {
        // 주문 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 접수에 실패했습니다'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: AppColors.loss,
        ),
      );
    }
  }

  void _setMaxQuantity() {
    // TODO: 실제 buying_power를 가져와서 최대 수량 계산
    // 현재는 임시로 100주로 설정
    final maxQuantity = 100;
    setState(() {
      _quantity = maxQuantity;
      _quantityController.text = maxQuantity.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              widget.symbol,
              style: AppFonts.titleMedium.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '체결가',
                      style: AppFonts.captionLargeSemiBold.copyWith(
                        color: AppColors.gray900,
                        height: 1.71,
                      ),
                    ),
                    Text(
                      '등락률',
                      style: AppFonts.captionLargeSemiBold.copyWith(
                        color: AppColors.profit,
                        height: 1.71,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 50), // 오른쪽 설정 아이콘과 균형 맞추기
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? Center(
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
                        style: AppFonts.bodyLarge.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExchangeRateAndStockDetail,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _stockDetail != null
                  ? Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildStockDetail(),
                              ),
                            ),
                            Container(
                          padding: const EdgeInsets.fromLTRB(72, 16, 72, 44),
                          child: Container(
                            width: 249,
                            height: 49,
                            decoration: ShapeDecoration(
                              color: AppColors.gray600.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildTabItem('차트', 0),
                                _buildTabItem('호가', 1),
                                _buildTabItem('주문', 2),
                                _buildTabItem('시세', 3),
                              ],
                            ),
                          ),
                        ),
                          ],
                        ),
                        // 세로선 (화면 전체, 탭바 제외) - 암호화폐일 때만 표시
                        if (_selectedTabIndex == 2 && _stockDetail?.assetClass == 'crypto') // 주문 탭이고 암호화폐일 때만 표시
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.45, // 조금 더 왼쪽으로 이동
                            top: 0,
                            bottom: 100, // 하단 탭바 높이만큼 제외
                            child: Container(
                              width: 1.3,
                              color: AppColors.gray100,
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Text('종목 정보가 없습니다'),
                    ),
    );
  }

  Widget _buildStockDetail() {
    final stock = _stockDetail!;
    
    return Column(
      children: [
        // 주식명 섹션 (주문 탭에서는 숨김)
        if (_selectedTabIndex != 2) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stock.name,
                        style: AppFonts.titleMedium.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                          height: 1.20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 이동 아이콘
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(
                        Icons.open_with,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 설정 아이콘
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // 시간 선택 섹션 (주문 탭에서는 숨김)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08, // 약 30-35px
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeOption('30m', false),
                _buildTimeOption('1h', true),
                _buildTimeOption('4h', false),
                _buildTimeOption('1d', false),
                _buildTimeOption('기타 ▾', false),
              ],
            ),
          ),
        ],
        
        // 탭별 콘텐츠
        _buildTabContent(),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // 차트
        return _buildChartTab();
      case 1: // 호가
        return _buildQuoteTab();
      case 2: // 주문
        return _buildOrderTab();
      case 3: // 시세
        return _buildMarketTab();
      default:
        return _buildChartTab();
    }
  }

  Widget _buildChartTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          '차트 영역',
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
              child: Text(
          '호가 영역\n(구현 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTab() {
    // assetClass에 따라 레이아웃 분기
    final isCrypto = _stockDetail?.assetClass == 'crypto';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8), // 하단 여백을 20에서 8로 줄임
      child: isCrypto 
        ? Row(
            children: [
              // 암호화폐: 좌측 호가창 + 우측 주문 폼
              Expanded(
                flex: 40,
                child: _buildOrderBook(),
              ),
              const SizedBox(width: 14), // 와이어프레임 기준 14px 여백
              const SizedBox(width: 1.3), // 세로선 공간
              const SizedBox(width: 16), // 중앙 여백을 16px로 늘림
              Expanded(
                flex: 60,
                child: _buildOrderForm(),
              ),
            ],
          )
        : Column(
            children: [
              // 미국 주식: 주문 폼만 전체 너비로 표시
              Expanded(
                child: _buildOrderForm(),
              ),
            ],
          ),
    );
  }

  Widget _buildOrderBook() {
    return SizedBox(
      height: 400, // 고정 높이 설정
      child: Center(
        child: Text(
          '호가창',
          style: AppFonts.bodyLarge.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderForm() {
    // assetClass에 따라 정렬 방식 분기
    final isCrypto = _stockDetail?.assetClass == 'crypto';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16), 
      child: Column(
        crossAxisAlignment: isCrypto ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // 매수/매도/내역 탭
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
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
              // 전체 너비의 gray100 밑줄
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.gray100,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 지정가 드롭다운 (assetClass에 따라 정렬)
          SizedBox(
            width: isCrypto ? 188 : double.infinity,
            child: Text(
              '지정가 ▾',
              textAlign: isCrypto ? TextAlign.right : TextAlign.center,
              style: AppFonts.bodySmallSemiBold.copyWith(
                color: AppColors.gray900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          
          // 주문가능 금액
          Text(
            '주문가능금액',
            textAlign: isCrypto ? TextAlign.right : TextAlign.center,
            style: AppFonts.btn2.copyWith(
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 9),
          
          // 수량 입력 필드
          Container(
            width: isCrypto ? 188 : double.infinity,
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
                        style: AppFonts.bodySmall.copyWith(
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
                                style: AppFonts.bodyMedium.copyWith(
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
                              style: AppFonts.bodyMedium.copyWith(
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
                          style: AppFonts.bodySmallSemiBold.copyWith(
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
            width: isCrypto ? 188 : double.infinity,
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
                    style: AppFonts.bodySmall.copyWith(
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
                                style: AppFonts.bodyMedium.copyWith(
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
                              style: AppFonts.bodyMedium.copyWith(
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
                              final tickSize = _tickSizeInKrw ?? 13.0; // 기본 틱 사이즈 (1300원 환율 기준)
                              setState(() {
                                _price = (_price - tickSize).clamp(0, double.infinity);
                                _priceController.text = _price.toStringAsFixed(0);
                              });
                            },
                            child: Text(
                              '−',
                              style: AppFonts.bodySmallSemiBold.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final tickSize = _tickSizeInKrw ?? 13.0; // 기본 틱 사이즈 (1300원 환율 기준)
                              setState(() {
                                _price = _price + tickSize;
                                _priceController.text = _price.toStringAsFixed(0);
                              });
                            },
                            child: Text(
                              '+',
                              style: AppFonts.bodySmallSemiBold.copyWith(
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
          const SizedBox(height: 80), // 가격 필드와 총액 사이 여백 더 증가
          
          // 총액 (assetClass에 따라 정렬)
          Padding(
            padding: EdgeInsets.only(left: isCrypto ? 8 : 0), // 암호화폐일 때만 오른쪽으로 이동
            child: Column(
              crossAxisAlignment: isCrypto ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  '총액',
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 8), // 간격을 늘림
                Text(
                  '${(_quantity * _price).toStringAsFixed(0)}원',
                  style: AppFonts.titleLarge.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // 총액과 매수 버튼 사이 여백 줄임
          
          
          const SizedBox(height: 8),
          
          // 매수/매도 버튼
          GestureDetector(
            onTap: _handleOrderSubmit,
            child: Container(
              width: isCrypto ? 188 : double.infinity,
              height: 55,
              decoration: BoxDecoration(
                color: _selectedOrderTab == '매도' ? AppColors.loss : AppColors.profit,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _selectedOrderTab == '매도' ? '매도' : '매수',
                  style: AppFonts.titleLarge.copyWith(
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

  Widget _buildOrderInputField(String label, String value, {
    String? prefix,
    String? suffix,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[
                GestureDetector(
                  onTap: () {
                    // 가격 조정 로직
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      prefix,
                      style: AppFonts.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: AppFonts.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (suffix != null) ...[
                GestureDetector(
                  onTap: () {
                    // 버튼 액션 로직
                  },
                  child: Text(
                    suffix,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showOrderBottomSheet() {
    if (_stockDetail == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderBottomSheet(
        symbol: widget.symbol,
        stockName: _stockDetail!.name,
        currentPrice: _stockDetail!.currentPrice ?? 0.0,
      ),
    );
  }

  Widget _buildMarketTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          '시세 영역\n(구현 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeItem(String label, int index) {
    final isSelected = _selectedTimeframeIndex == index;
    
    return GestureDetector(
      onTap: () {
                          setState(() {
          _selectedTimeframeIndex = index;
                          });
                        },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.gray600,
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(72, 16, 72, 20),
      child: Container(
        height: 49,
        decoration: ShapeDecoration(
          color: const Color(0x997F7F7F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTabItem('차트', 0),
            _buildTabItem('호가', 1),
            _buildTabItem('주문', 2),
            _buildTabItem('시세', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            height: 1.50,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 선택된 시간 옵션 업데이트 로직 추가 가능
        });
      },
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 1.40,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              width: 20,
              height: 2,
              color: AppColors.gray900,
            ),
        ],
      ),
    );
  }
}