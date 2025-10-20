import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';
import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:qbit_shared/widgets/common/padding/horizontal_inset.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_detail_navigation.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:go_router/go_router.dart';

// OrderModel - API 응답 데이터 모델
class OrderModel {
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

  OrderModel({
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'],
      alpacaOrderId: json['alpacaOrderId'],
      symbol: json['symbol'],
      side: json['side'],
      quantity: json['quantity'],
      filledQuantity: json['filledQuantity'],
      filledAvgPrice: json['filledAvgPrice'],
      type: json['type'],
      timeInForce: json['timeInForce'],
      limitPrice: json['limitPrice'],
      stopPrice: json['stopPrice'],
      status: json['status'],
      createdAt: json['createdAt'],
      submittedAt: json['submittedAt'],
      filledAt: json['filledAt'],
      canceledAt: json['canceledAt'],
      replacedAt: json['replacedAt'],
      replacedBy: json['replacedBy'],
      replaces: json['replaces'],
    );
  }
}

// 날짜 포맷팅 함수 (MM.DD)
String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  } catch (e) {
    return '--.--';
  }
}

// 상태 라벨 생성 함수
String _getStatusLabel(OrderModel order) {
  if (order.status == 'filled') {
    return order.side == 'buy' ? '구매 완료' : '매도 완료';
  } else if (order.status == 'accepted' || order.status == 'pending_new') {
    return order.type == 'limit' ? '지정가 대기' : '시장가 대기';
  } else if (order.status == 'canceled') {
    return '취소됨';
  } else {
    return '처리 중';
  }
}

// 수량과 가격 포맷팅 함수
String _formatQuantityAndPrice(OrderModel order) {
  final quantity = double.tryParse(order.quantity) ?? 0;
  final price = order.filledAvgPrice != null 
      ? double.tryParse(order.filledAvgPrice!) 
      : order.limitPrice != null 
          ? double.tryParse(order.limitPrice!) 
          : null;
  
  if (price != null) {
    return '${quantity.toStringAsFixed(2)}주 · \$${price.toStringAsFixed(2)}';
  } else {
    return '${quantity.toStringAsFixed(2)}주';
  }
}

class CycleItem {
  final String dateRange;    // "25.10.03-25.10.17"
  final String companyName;  // "Apple Inc."
  final String ticker;       // "AAPL"
  final String? logoUrl;     // 로고 URL

  const CycleItem({
    required this.dateRange,
    required this.companyName,
    required this.ticker,
    this.logoUrl,
  });
}

// 사이클 데모 데이터
final demoCycles = <CycleItem>[
  CycleItem(
    dateRange: '2025.10.03-2025.10.17',
    companyName: 'Figma Inc.',
    ticker: 'FIG',
  ),
];

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = false;
  List<OrderModel> _orders = [];
  List<CycleItem> _cycleData = [];
  StreamSubscription? _wsSub;
  bool _wsConnected = false;
  
  // 탭 상태
  String _selectedTab = '개별'; // 개별, 사이클
  String _selectedFilter = '전체'; // 전체, 매수, 매도

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _loadCycleData();
    _connectWs();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await OrderApiService.getOrderHistory();
      
      if (mounted) {
        setState(() {
          _orders = response?['content']?.map<OrderModel>((json) => OrderModel.fromJson(json)).toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (error) {
      print('주문 내역 조회 실패: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 사이클 데이터 로드 (데모 데이터 사용)
  void _loadCycleData() {
    setState(() {
      _cycleData = demoCycles;
    });
  }

  void _connectWs() {
    // WebSocket 연결 (현재는 비활성화)
    // TODO: WebSocket 서비스 구현 후 활성화
    setState(() {
      _wsConnected = false;
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '주문 내역',
        onBackPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          // 탭 선택
          _buildTabSelector(),
          
          // 필터 버튼
          _buildFilterButtons(),
          
          // 내용
          Expanded(
            child: _selectedTab == '개별' ? _buildOrderList() : _buildCycleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = '개별'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == '개별' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == '개별' ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  '개별',
                  textAlign: TextAlign.center,
                  style: AppFonts.b2Semibold.copyWith(
                    color: _selectedTab == '개별' ? AppColors.gray900 : AppColors.gray600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = '사이클'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == '사이클' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == '사이클' ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  '사이클',
                  textAlign: TextAlign.center,
                  style: AppFonts.b2Semibold.copyWith(
                    color: _selectedTab == '사이클' ? AppColors.gray900 : AppColors.gray600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    if (_selectedTab != '개별') return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          FilterButton(
            label: '전체',
            isSelected: _selectedFilter == '전체',
            onTap: () => setState(() => _selectedFilter = '전체'),
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: '매수',
            isSelected: _selectedFilter == '매수',
            onTap: () => setState(() => _selectedFilter = '매수'),
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: '매도',
            isSelected: _selectedFilter == '매도',
            onTap: () => setState(() => _selectedFilter = '매도'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == '전체') return true;
      if (_selectedFilter == '매수') return order.side == 'buy';
      if (_selectedFilter == '매도') return order.side == 'sell';
      return true;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              '주문 내역이 없습니다',
              style: AppFonts.b1Semibold.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderItem(order);
      },
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: 352,
      height: 37,
      child: Stack(
        children: [
          // 날짜 (MM.DD)
          Positioned(
            left: 0,
            top: 11,
            child: Text(
              _formatDate(order.createdAt),
              style: AppFonts.c1.copyWith(
                color: AppColors.gray900,
                fontSize: 14,
                height: 1.21,
              ),
            ),
          ),
          
          // 상태 라벨 (구매 완료, 지정가 대기 등)
          Positioned(
            left: 56,
            top: 20,
            child: Text(
              _getStatusLabel(order),
              style: AppFonts.c1.copyWith(
                color: AppColors.primary,
                fontSize: 13,
                height: 1.31,
              ),
            ),
          ),
          
          // 수량과 가격 (1.25주 · $245.61)
          Positioned(
            left: 252,
            top: 10,
            child: Text(
              _formatQuantityAndPrice(order),
              style: AppFonts.c1.copyWith(
                color: AppColors.gray900,
                fontSize: 14,
                height: 1.21,
              ),
            ),
          ),
          
          // 심볼 (ETHUSD)
          Positioned(
            left: 56,
            top: 0,
            child: SizedBox(
              width: 71,
              height: 16,
              child: Text(
                order.symbol,
                style: AppFonts.b2Semibold.copyWith(
                  color: AppColors.gray900,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_cycleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              '사이클 데이터가 없습니다',
              style: AppFonts.b1Semibold.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cycleData.length,
      itemBuilder: (context, index) {
        final cycle = _cycleData[index];
        return _buildCycleItem(cycle);
      },
    );
  }

  Widget _buildCycleItem(CycleItem cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width - 32,
      height: 89,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              height: 89,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      height: 89,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 8,
                            top: 0,
                            child: SizedBox(
                              width: 103,
                              height: 18.03,
                              child: Text(
                                cycle.dateRange,
                                style: TextStyle(
                                  color: const Color(0xFF7F7F7F) /* Gray-600 */,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  height: 1.23,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 18.03,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 32,
                              height: 65.34,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width - 32,
                                      height: 65.34,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 8,
                                            top: 11,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: ShapeDecoration(
                                                    color: const Color(0xFFFFFBF3) /* Secondary-BG */,
                                                    shape: OvalBorder(),
                                                  ),
                                                  child: Center(
                                                    child: _buildCompanyLogo(cycle.ticker),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      cycle.companyName,
                                                      style: TextStyle(
                                                        color: const Color(0xFF323232) /* Gray-900(Font-Black) */,
                                                        fontSize: 16,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w600,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      cycle.ticker,
                                                      style: TextStyle(
                                                        color: const Color(0xFF7F7F7F) /* Gray-600 */,
                                                        fontSize: 14,
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w400,
                                                        height: 1.21,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                  ),
                ],
              ),
            ),
          ),
          
          // 리포트 아이콘
          Positioned(
            right: 8,
            top: 32,
            child: GestureDetector(
              onTap: () {
                print('리포트 아이콘 클릭됨!');
                context.push('/trade-report');
              },
              child: SvgPicture.asset(
                'assets/icons/report.svg',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 회사 로고 빌드 함수
  Widget _buildCompanyLogo(String ticker) {
    switch (ticker.toUpperCase()) {
      case 'FIG':
        return SvgPicture.asset(
          'assets/images/figma.svg',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        );
      default:
        return Icon(
          Icons.business,
          size: 20,
          color: AppColors.gray400,
        );
    }
  }
}