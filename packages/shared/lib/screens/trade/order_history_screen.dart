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
import 'package:qbit_services/api/order_websocket_service.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_services/models/trade_cycle.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

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
  // 디버깅: 실제 주문 상태 출력
  print('🔍 주문 상태 체크: ${order.symbol}, status=${order.status}, filledQuantity=${order.filledQuantity}, filledAvgPrice=${order.filledAvgPrice}');
  
  // 체결된 수량이 있으면 완료로 표시
  if (order.filledQuantity != null && order.filledQuantity != '' && order.filledQuantity != '0' && order.filledQuantity != '0E-8' && order.filledQuantity != '0.00000000') {
    return order.side == 'buy' ? '구매 완료' : '매도 완료';
  }
  
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

// 심볼이 암호화폐인지 판단하는 함수
bool _isCryptoSymbol(String symbol) {
  // 일반적인 암호화폐 심볼 패턴들
  final cryptoPatterns = [
    'BTC', 'ETH', 'ADA', 'SOL', 'MATIC', 'AVAX', 'DOT', 'LINK', 'UNI', 'AAVE',
    'USDT', 'USDC', 'BUSD', 'DAI', 'WBTC', 'WETH', 'DOGE', 'SHIB', 'XRP', 'LTC'
  ];
  
  final upperSymbol = symbol.toUpperCase();
  
  // 심볼에서 암호화폐 패턴이 포함되어 있는지 확인
  // 단, 주식 심볼과 구분하기 위해 더 정확한 매칭 사용
  for (final pattern in cryptoPatterns) {
    if (upperSymbol.contains(pattern)) {
      // 추가 검증: 주식 심볼과 구분
      // 예: BTC/USD, ETH/USDT, BTCUSD 등은 암호화폐
      if (upperSymbol.contains('/') || upperSymbol.endsWith('USD') || upperSymbol.endsWith('USDT')) {
        return true;
      }
      // 단일 심볼인 경우 (BTC, ETH 등)
      if (upperSymbol == pattern) {
        return true;
      }
    }
  }
  
  return false;
}

// 수량과 가격 포맷팅 함수
String _formatQuantityAndPrice(OrderModel order) {
  final quantity = double.tryParse(order.quantity) ?? 0;
  final price = order.filledAvgPrice != null 
      ? double.tryParse(order.filledAvgPrice!) 
      : order.limitPrice != null 
          ? double.tryParse(order.limitPrice!) 
          : null;
  
  final isCrypto = _isCryptoSymbol(order.symbol);
  
  final quantityText = isCrypto 
      ? '${quantity.toStringAsFixed(9).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}개'
      : '${quantity.toStringAsFixed(2)}주';
  
  if (price != null) {
    final priceText = isCrypto 
        ? '\$${price.toStringAsFixed(2)}'
        : '\$${price.toStringAsFixed(2)}';
    return '$quantityText · $priceText';
  } else {
    return quantityText;
  }
}

class CycleItem {
  final String dateRange;    // "25.03.17-25.10.20"
  final String companyName;  // "Apple Inc. Common Stock"
  final String ticker;       // "AAPL"
  final String? logoUrl;     // 로고 URL
  final DateTime? buyDate;   // 매수 날짜
  final DateTime? sellDate;  // 매도 날짜

  const CycleItem({
    required this.dateRange,
    required this.companyName,
    required this.ticker,
    this.logoUrl,
    this.buyDate,
    this.sellDate,
  });
}

// 사이클 데이터는 웹소켓을 통해 실시간으로 받아옴

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
  
  // 삭제 관련 상태
  int? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
        
        // 주문 내역 로드 후 사이클 데이터 생성
        _loadCycleData();
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

  // 사이클 데이터 로드 
  void _loadCycleData() {
    // 매수와 매도 쌍을 찾아서 사이클 생성
    final cycles = <String, List<OrderModel>>{};
    
    // 1. 매수 주문 수집 (side == 'buy'이고 filled) - 모두 수집
    final buyOrders = <String, List<OrderModel>>{};
    for (final order in _orders) {
      if (order.side == 'buy' && 
          (order.status == 'filled' || 
           (order.filledQuantity != null && 
            order.filledQuantity != '' && 
            order.filledQuantity != '0' && 
            order.filledQuantity != '0E-8' && 
            order.filledQuantity != '0.00000000'))) {
        if (!buyOrders.containsKey(order.symbol)) {
          buyOrders[order.symbol] = [];
        }
        buyOrders[order.symbol]!.add(order);
      }
    }
    
    // 2. 매도 주문 수집 (side == 'sell'이고 filled) - 모두 수집
    final sellOrders = <String, List<OrderModel>>{};
    for (final order in _orders) {
      if (order.side == 'sell' && 
          (order.status == 'filled' || 
           (order.filledQuantity != null && 
            order.filledQuantity != '' && 
            order.filledQuantity != '0' && 
            order.filledQuantity != '0E-8' && 
            order.filledQuantity != '0.00000000'))) {
        if (!sellOrders.containsKey(order.symbol)) {
          sellOrders[order.symbol] = [];
        }
        sellOrders[order.symbol]!.add(order);
      }
    }
    
    // 3. 매수와 매도 모두 있는 심볼의 모든 가능한 쌍 생성
    final cycleItems = <CycleItem>[];
    
    for (final symbol in buyOrders.keys) {
      if (sellOrders.containsKey(symbol)) {
        final buys = buyOrders[symbol]!;
        final sells = sellOrders[symbol]!;
        
        // 각 매수에 대해 그 이후의 매도와 매칭
        for (final buyOrder in buys) {
          final buyDate = buyOrder.filledAt != null 
              ? DateTime.parse(buyOrder.filledAt!)
              : DateTime.parse(buyOrder.createdAt);
          
          // 매수 이후의 매도만 찾기
          for (final sellOrder in sells) {
            final sellDate = sellOrder.filledAt != null 
                ? DateTime.parse(sellOrder.filledAt!)
                : DateTime.parse(sellOrder.createdAt);
            
            // 매도가 매수 이후여야 함
            if (sellDate.isAfter(buyDate)) {
              cycleItems.add(CycleItem(
                dateRange: '${buyDate.year.toString().substring(2)}.${buyDate.month.toString().padLeft(2, '0')}.${buyDate.day.toString().padLeft(2, '0')}-${sellDate.year.toString().substring(2)}.${sellDate.month.toString().padLeft(2, '0')}.${sellDate.day.toString().padLeft(2, '0')}',
                companyName: symbol,
                ticker: symbol,
                buyDate: buyDate,
                sellDate: sellDate,
              ));
            }
          }
        }
      }
    }
    
    print('매수 주문 수: ${buyOrders.values.fold<int>(0, (sum, list) => sum + list.length)}');
    print('매도 주문 수: ${sellOrders.values.fold<int>(0, (sum, list) => sum + list.length)}');
    print('생성된 사이클 수: ${cycleItems.length}');
    
    // 사이클 아이템 생성
    setState(() {
      _cycleData = cycleItems
        ..sort((a, b) {
          // 매도 날짜가 가장 최신인 순으로 정렬
          if (a.sellDate == null && b.sellDate == null) return 0;
          if (a.sellDate == null) return 1;
          if (b.sellDate == null) return -1;
          return b.sellDate!.compareTo(a.sellDate!);
        });
      
      print('사이클 데이터 로드 완료: ${_cycleData.length}개');
    });
  }

  void _connectWs() {
    print('WebSocket 연결 시작...');
    // WebSocket 연결 및 실시간 주문 상태 업데이트 구독
    OrderWebSocketService.instance.connect();
    
    // WebSocket 연결 상태 확인
    print('WebSocket 연결 상태: ${OrderWebSocketService.instance.isConnected}');
    
    // 개별 주문 업데이트 구독
    _wsSub = OrderWebSocketService.instance.orderUpdates.listen((orderUpdate) {
      print('실시간 주문 업데이트 수신: $orderUpdate');
      
      if (mounted) {
        setState(() {
          _wsConnected = true;
        });
        
        // 주문 상태 업데이트 처리
        _handleOrderUpdate(orderUpdate);
        
        // 주문이 완료되면 사이클 데이터 다시 로드
        if (orderUpdate.status?.toUpperCase() == 'FILLED') {
          _loadCycleData();
        }
      }
    }, onError: (error) {
      print('WebSocket 에러: $error');
      if (mounted) {
        setState(() {
          _wsConnected = false;
        });
      }
    });
  }

  // 실시간 주문 상태 업데이트 처리
  void _handleOrderUpdate(OrderUpdateMessage orderUpdate) {
    try {
      final orderId = orderUpdate.orderId;
      final newStatus = orderUpdate.status;
      
      if (orderId != null && newStatus != null) {
        // 기존 주문 목록에서 해당 주문 찾아서 상태 업데이트
        final orderIndex = _orders.indexWhere((order) => order.orderId == orderId);
        
        if (orderIndex != -1) {
          final updatedOrder = OrderModel(
            orderId: _orders[orderIndex].orderId,
            alpacaOrderId: _orders[orderIndex].alpacaOrderId,
            symbol: _orders[orderIndex].symbol,
            side: _orders[orderIndex].side,
            quantity: _orders[orderIndex].quantity,
            filledQuantity: orderUpdate.filledQuantity?.toString() ?? _orders[orderIndex].filledQuantity,
            filledAvgPrice: orderUpdate.filledAvgPrice?.toString() ?? _orders[orderIndex].filledAvgPrice,
            type: _orders[orderIndex].type,
            timeInForce: _orders[orderIndex].timeInForce,
            limitPrice: _orders[orderIndex].limitPrice,
            stopPrice: _orders[orderIndex].stopPrice,
            status: newStatus,
            createdAt: _orders[orderIndex].createdAt,
            submittedAt: _orders[orderIndex].submittedAt,
            filledAt: orderUpdate.filledAt?.toIso8601String() ?? _orders[orderIndex].filledAt,
            canceledAt: _orders[orderIndex].canceledAt,
            replacedAt: _orders[orderIndex].replacedAt,
            replacedBy: _orders[orderIndex].replacedBy,
            replaces: _orders[orderIndex].replaces,
          );
          
          setState(() {
            _orders[orderIndex] = updatedOrder;
          });
          
          print('주문 $orderId 상태 업데이트: ${_orders[orderIndex].status}');
        }
      }
    } catch (e) {
      print('주문 업데이트 처리 실패: $e');
    }
  }

  // 주문 삭제 메서드
  Future<void> _deleteOrder(int orderId) async {
    try {
      final success = await OrderApiService.cancelOrder(orderId.toString());
      
      if (success) {
        // 성공 시 로컬 목록에서도 제거
        setState(() {
          _orders.removeWhere((order) => order.orderId == orderId);
          _selectedOrderId = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('주문이 삭제되었습니다'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('주문 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      print('주문 삭제 에러: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주문 삭제 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 삭제 확인 다이얼로그
  void _showDeleteDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('주문 삭제'),
          content: Text('${order.symbol} 주문을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedOrderId = null;
                });
              },
              child: Text(
                '취소',
                style: TextStyle(color: AppColors.gray600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOrder(order.orderId);
              },
              child: Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    // WebSocket 연결은 다른 화면에서도 사용할 수 있으므로 여기서는 구독만 취소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '주문 내역 조회',
        onBackPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          // 탭 선택
          _buildTabSelector(),
          
          // WebSocket 연결 상태 표시
          if (_wsConnected)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(4)),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: context.w(8),
                    height: context.h(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    '실시간 업데이트 중',
                    style: AppFonts.c2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          
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
      padding: EdgeInsets.only(left: context.w(20), right: context.w(20), top: 0, bottom: context.h(16)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTab = '개별'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: context.h(8), horizontal: context.w(16)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1.3,
                    color: _selectedTab == '개별' ? AppColors.gray900 : Colors.transparent,
                  ),
                ),
              ),
              child: Text(
                '개별',
                style: TextStyle(
                  color: _selectedTab == '개별' ? AppColors.gray900 : AppColors.gray300,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  height: 1.31,
                ),
              ),
            ),
          ),
          SizedBox(width: context.w(17)),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = '사이클'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: context.h(8), horizontal: context.w(16)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1.3,
                    color: _selectedTab == '사이클' ? AppColors.gray900 : Colors.transparent,
                  ),
                ),
              ),
              child: Text(
                '사이클',
                style: TextStyle(
                  color: _selectedTab == '사이클' ? AppColors.gray900 : AppColors.gray300,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  height: 1.31,
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
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      margin: EdgeInsets.only(top: context.h(8), bottom: context.h(8)),
      child: Row(
        children: [
          FilterButton(
            label: '전체',
            isSelected: _selectedFilter == '전체',
            onTap: () => setState(() => _selectedFilter = '전체'),
          ),
          SizedBox(width: context.w(8)),
          FilterButton(
            label: '매수',
            isSelected: _selectedFilter == '매수',
            onTap: () => setState(() => _selectedFilter = '매수'),
          ),
          SizedBox(width: context.w(8)),
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
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순으로 정렬

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: context.w(64),
              color: AppColors.gray400,
            ),
            SizedBox(height: context.h(16)),
            Text(
              '주문 내역이 없습니다',
              style: AppFonts.b1Semibold.copyWith(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: context.h(16)),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderItem(order);
      },
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    final isSelected = _selectedOrderId == order.orderId;
    
    return Container(
      margin: EdgeInsets.only(bottom: context.h(24)),
      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 (MM.DD)
          Container(
            width: context.w(40),
            padding: EdgeInsets.only(top: context.h(11)),
            child: Text(
              _formatDate(order.createdAt),
              style: AppFonts.c1.copyWith(
                color: AppColors.gray900,
                fontSize: 14,
                height: 1.21,
              ),
            ),
          ),
          
          SizedBox(width: context.w(16)),
          
          // 심볼과 상태
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                setState(() {
                  _selectedOrderId = isSelected ? null : order.orderId;
                });
              },
              onTap: () {
                if (isSelected) {
                  _showDeleteDialog(order);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.symbol,
                    style: AppFonts.b2Semibold.copyWith(
                      color: AppColors.gray900,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    _getStatusLabel(order),
                    style: AppFonts.c1.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                      height: 1.31,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 수량과 가격 또는 삭제 버튼
          if (isSelected)
            GestureDetector(
              onTap: () => _showDeleteDialog(order),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.w(12), vertical: context.h(6)),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '삭제',
                  style: AppFonts.c1.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Text(
              _formatQuantityAndPrice(order),
              style: AppFonts.c1.copyWith(
                color: AppColors.gray900,
                fontSize: 14,
                height: 1.21,
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
            Text(
              '완료된 거래 사이클이 없습니다',
              style: AppFonts.b1Regular.copyWith(
                color: AppColors.gray400,
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              '매수부터 전량 매도까지 완료된 거래가 여기에 표시됩니다.',
              style: AppFonts.c2.copyWith(
                color: AppColors.gray300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      itemCount: _cycleData.length,
      itemBuilder: (context, index) {
        final cycle = _cycleData[index];
        return _buildCycleItem(cycle);
      },
    );
  }

  Widget _buildCycleItem(CycleItem cycle) {
    String dateRangeText = cycle.dateRange;
    
    return Container(
      width: double.infinity,
      height: context.h(89),
      child: Stack(
        children: [
          // 날짜 범위
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              dateRangeText,
                style: AppFonts.c1.copyWith(
                  color: AppColors.gray600,
                  height: 1.23,
                ),
            ),
          ),
          
          // 메인 컨텐츠 영역
          Positioned(
            left: 0,
            top: context.h(25),
            right: 0,
            child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 회사 로고 (원형)
                    Container(
                      width: context.w(44),
                      height: context.h(44),
                      decoration: const ShapeDecoration(
                        color: AppColors.secondaryBG,
                        shape: OvalBorder(),
                      ),
                      child: Center(
                        child: cycle.logoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  cycle.logoUrl!,
                                  width: context.w(44),
                                  height: context.h(44),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildCompanyLogo(cycle.ticker);
                                  },
                                ),
                              )
                            : _buildCompanyLogo(cycle.ticker),
                      ),
                    ),
                    
                    SizedBox(width: context.w(12)),
                    
                    // 회사 정보 (심볼명만 표시)
                    Text(
                      cycle.ticker,
                      style: AppFonts.b1Regular.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    
                    // 분석 아이콘
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        context.push('/trade-report');
                      },
                      child: Container(
                        width: context.w(24),
                        height: context.h(24),
                        padding: EdgeInsets.all(context.w(4)),
                        child: SvgPicture.asset(
                          'assets/icons/report.svg',
                          width: context.w(23),
                          height: context.h(23),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo(String ticker) {
    return Container(
      width: context.w(40),
      height: context.h(40),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          ticker.substring(0, 1).toUpperCase(),
          style: AppFonts.b1Semibold.copyWith(
            color: AppColors.gray600,
          ),
        ),
      ),
    );
  }
}
