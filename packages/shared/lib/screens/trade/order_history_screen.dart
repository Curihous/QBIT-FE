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
  StreamSubscription? _wsCycleSub; // 사이클 업데이트 구독
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

  // 사이클 데이터 로드 (웹소켓을 통해 실시간으로 받아옴)
  void _loadCycleData() {
    setState(() {
      _cycleData = []; // 빈 리스트로 초기화
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
      }
    }, onError: (error) {
      print('WebSocket 에러: $error');
      if (mounted) {
        setState(() {
          _wsConnected = false;
        });
      }
    });
    
    // 사이클 업데이트 구독
    _wsCycleSub = OrderWebSocketService.instance.tradeCycleUpdates.listen((cycleUpdate) {
      print('실시간 사이클 업데이트 수신: $cycleUpdate');
      print('사이클 업데이트 상세: symbol=${cycleUpdate.symbol}, side=${cycleUpdate.side}, executedAt=${cycleUpdate.executedAt}');
      
      if (mounted) {
        setState(() {
          _wsConnected = true;
        });
        
        // 사이클 업데이트 처리
        _handleCycleUpdate(cycleUpdate);
      }
    }, onError: (error) {
      print('사이클 업데이트 WebSocket 에러: $error');
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

  // 실시간 사이클 업데이트 처리
  void _handleCycleUpdate(TradeCycle cycleUpdate) {
    try {
      print('사이클 업데이트 처리 시작: ${cycleUpdate.symbol}');
      print('현재 사이클 데이터 개수: ${_cycleData.length}');
      
      // 사이클 데이터를 CycleItem 형태로 변환
      final newCycleItem = CycleItem(
        dateRange: '${cycleUpdate.executedAt.year}.${cycleUpdate.executedAt.month.toString().padLeft(2, '0')}.${cycleUpdate.executedAt.day.toString().padLeft(2, '0')}',
        companyName: cycleUpdate.symbol,
        ticker: cycleUpdate.symbol,
      );
      
      print('새로운 사이클 아이템 생성: $newCycleItem');
      
      setState(() {
        // 중복 체크 후 추가
        final existingCycle = _cycleData.any((cycle) => cycle.ticker == cycleUpdate.symbol);
        print('중복 체크 결과: $existingCycle');
        
        if (!existingCycle) {
          _cycleData.add(newCycleItem);
          print('사이클 데이터 추가됨. 새로운 개수: ${_cycleData.length}');
        } else {
          print('중복된 사이클이므로 추가하지 않음');
        }
      });
      
      print('사이클 업데이트 완료: ${cycleUpdate.symbol}');
    } catch (e) {
      print('사이클 업데이트 처리 실패: $e');
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsCycleSub?.cancel(); // 사이클 구독 취소
    // WebSocket 연결은 다른 화면에서도 사용할 수 있으므로 여기서는 구독만 취소
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
          
          // WebSocket 연결 상태 표시
          if (_wsConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
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
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬

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
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 (MM.DD)
          Container(
            width: 40,
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              _formatDate(order.createdAt),
              style: AppFonts.c1.copyWith(
                color: AppColors.gray900,
                fontSize: 14,
                height: 1.21,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
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
                  const SizedBox(height: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 8),
            Text(
              '매수부터 매도까지 완료된 거래가 여기에 표시됩니다',
              style: AppFonts.c2.copyWith(
                color: AppColors.gray300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _cycleData.length,
      itemBuilder: (context, index) {
        final cycle = _cycleData[index];
        return _buildCycleItem(cycle);
      },
    );
  }

  Widget _buildCycleItem(CycleItem cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          // 회사 로고
          _buildCompanyLogo(cycle.ticker),
          const SizedBox(width: 12),
          
          // 사이클 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycle.companyName,
                  style: AppFonts.b1Semibold.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cycle.ticker,
                  style: AppFonts.c2.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cycle.dateRange,
                  style: AppFonts.c2.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          
          // 화살표
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.gray300,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo(String ticker) {
    return Container(
      width: 40,
      height: 40,
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