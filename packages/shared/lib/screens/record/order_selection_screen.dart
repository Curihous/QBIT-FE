import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/widgets/common/header/header_back.dart';
import 'package:qbit_shared/widgets/common/button/big_black_button.dart';
import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';
import 'package:qbit_shared/models/order_history_model.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:intl/intl.dart';

/// 주문 선택 화면
class OrderSelectionScreen extends StatefulWidget {
  const OrderSelectionScreen({super.key});

  @override
  State<OrderSelectionScreen> createState() => _OrderSelectionScreenState();
}

class _OrderSelectionScreenState extends State<OrderSelectionScreen> {
  List<OrderHistoryModel> _orders = [];
  bool _isLoading = false;
  int? _selectedOrderId;
  String _selectedSide = 'ALL'; // 'ALL', 'buy', 'sell'
  final TextEditingController _searchController = TextEditingController();
  String? _searchSymbol;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await OrderApiService.getOrderHistory(
        page: 0,
        size: 100,
        symbol: _searchSymbol,
        side: _selectedSide == 'ALL' ? null : _selectedSide,
        hasJournal: false, // 기록이 없는 주문만 불러오기
        asset: 'us_equity',
      );

      if (response != null && mounted) {
        final content = response['content'] as List<dynamic>?;
        if (content != null) {
          setState(() {
            _orders = content
                .map((item) => OrderHistoryModel.fromJson(
                    item as Map<String, dynamic>))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

      void _onOrderSelected(int orderId) {
        setState(() {
          // 이미 선택된 항목을 다시 누르면 선택 해제
          if (_selectedOrderId == orderId) {
            _selectedOrderId = null;
          } else {
            _selectedOrderId = orderId;
          }
        });
      }

  void _onSideFilterChanged(String side) {
    setState(() {
      _selectedSide = side;
    });
    _loadOrders();
  }

  String _formatOrderDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yy.MM.dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _onConfirm() {
    if (_selectedOrderId != null) {
      Navigator.of(context).pop(_selectedOrderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: '주문 선택',
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppColors.gray600,
            ),
            onPressed: () {
              // 검색 기능 구현 (필요시)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 버튼
          Inset.block(
            child: FilterButtonGroup(
              labels: ['전체', '매수', '매도'],
              values: ['ALL', 'buy', 'sell'],
              initialValue: _selectedSide,
              onChanged: _onSideFilterChanged,
              groupPadding: EdgeInsets.only(
                top: context.h(12),
                bottom: context.h(6),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Text(
                          '주문 내역이 없습니다',
                          style: TextStyle(color: AppColors.gray600),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: context.h(8),
                          bottom: context.h(8),
                        ),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final isSelected = _selectedOrderId == order.orderId;
                          final sideColor = order.side.toLowerCase() == 'buy' 
                              ? AppColors.chartRed 
                              : AppColors.chartBlue;
                          
                          return GestureDetector(
                            onTap: () => _onOrderSelected(order.orderId),
                            child: Container(
                              margin: EdgeInsets.only(bottom: context.h(16)),
                              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                              height: context.h(83.367),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryBG : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 주문 요청일
                                  Text(
                                    _formatOrderDate(order.createdAt),
                                    style: AppFonts.c1.copyWith(
                                      color: AppColors.gray600,
                                      fontSize: 13,
                                      height: 1.23,
                                    ),
                                  ),
                                  SizedBox(height: context.h(4)),
                                  // 본문 영역
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 로고 이미지
                                      Container(
                                        width: context.w(42),
                                        height: context.h(42),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryBG,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.gray100,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: order.logoUrl != null && order.logoUrl!.isNotEmpty
                                              ? Image.network(
                                                  order.logoUrl!,
                                                  width: context.w(42),
                                                  height: context.h(42),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return SvgPicture.asset(
                                                      'assets/icons/stock_search_screen/company-logo-basic.svg',
                                                      width: context.w(42),
                                                      height: context.h(42),
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                              : SvgPicture.asset(
                                                  'assets/icons/stock_search_screen/company-logo-basic.svg',
                                                  width: context.w(42),
                                                  height: context.h(42),
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      SizedBox(width: context.w(12)),
                                      // 심볼 / 수량·가격
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // 좌측: 심볼 + 수량·가격 (2줄)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // 심볼
                                                  Text(
                                                    order.symbol,
                                                    style: AppFonts.b1Semibold.copyWith(
                                                      color: AppColors.gray900,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  SizedBox(height: context.h(4)),
                                                  // 수량·가격
                                                  Text(
                                                    order.formattedQuantityAndPrice,
                                                    style: AppFonts.c1.copyWith(
                                                      color: sideColor,
                                                      fontSize: 13,
                                                      height: 1.23,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: context.w(8)),
                                            // 우측: 주문 상태
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  order.statusInKorean,
                                                  style: AppFonts.c1.copyWith(
                                                    color: AppColors.gray600,
                                                    fontSize: 13,
                                                    height: 1.23,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // 확인 버튼 (선택된 주문 정보 표시)
          Container(
            padding: EdgeInsets.only(
              top: context.h(16),
              bottom: context.h(16),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.main,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(16)),
              child: BigBlackButton(
                text: '확인',
                onPressed: _selectedOrderId != null ? _onConfirm : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

