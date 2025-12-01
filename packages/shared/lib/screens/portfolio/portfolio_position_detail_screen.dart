import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/app_header.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/api/exchange_rate_api_service.dart';
import 'package:qbit_services/api/order_api_service.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_shared/widgets/common/loading_widget.dart';
import 'package:qbit_shared/widgets/common/error_widget.dart' as common_error;
import 'package:qbit_shared/widgets/common/button/big_black_button.dart';

class PortfolioPositionDetailScreen extends StatefulWidget {
  final String symbol;

  const PortfolioPositionDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<PortfolioPositionDetailScreen> createState() => _PortfolioPositionDetailScreenState();
}

class _PortfolioPositionDetailScreenState extends State<PortfolioPositionDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _positionData;
  double? _exchangeRate;
  List<Map<String, dynamic>>? _orderHistory;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StockApiService.getPortfolioPositions(),
        ExchangeRateApiService.getUsdToKrwRate(),
        OrderApiService.getOrders(symbol: widget.symbol),
      ]);

      if (mounted) {
        final allPositions = results[0] as List<Map<String, dynamic>>?;
        final position = allPositions?.firstWhere(
          (element) => element['symbol'] == widget.symbol,
          orElse: () => {},
        );

        setState(() {
          _positionData = (position != null && position.isNotEmpty) ? position : null;
          _exchangeRate = results[1] as double?;
          _orderHistory = results[2] as List<Map<String, dynamic>>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: widget.symbol,
        showBack: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_error != null) {
      return Center(
        child: common_error.ErrorWidget(
          message: '정보를 불러오는데 실패했습니다.\n$_error',
          onRetry: _fetchData,
        ),
      );
    }

    if (_positionData == null) {
      return Center(
        child: common_error.ErrorWidget(
          message: '보유 정보를 찾을 수 없습니다.',
          onRetry: _fetchData,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(_positionData!),
          // Divider removed as per user request
          _buildSummarySection(_positionData!),
          SizedBox(height: context.h(24)),
          // Action buttons removed as per user request
          SizedBox(height: context.h(8)),
          _buildOrderHistorySection(),
          SizedBox(height: context.h(40)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> position) {
    final avgEntryPrice = double.tryParse(position['avgEntryPrice']?.toString() ?? '0') ?? 0.0;
    
    return Container(
      padding: EdgeInsets.all(context.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1주 평균금액',
            style: AppFonts.b2Regular.copyWith(
              color: AppColors.gray600,
              fontSize: context.f(14),
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            _formatPriceWithKrw(avgEntryPrice, showUsd: false), // Show KRW primarily as per design
            style: AppFonts.t1Bold.copyWith(
              color: AppColors.gray900,
              fontSize: context.f(32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> position) {
    final quantity = double.tryParse(position['qty']?.toString() ?? position['quantity']?.toString() ?? '0') ?? 0.0;
    final marketValue = double.tryParse(position['marketValue']?.toString() ?? '0') ?? 0.0;
    final costBasis = double.tryParse(position['costBasis']?.toString() ?? '0') ?? 0.0;
    final unrealizedPl = double.tryParse(position['unrealizedPl']?.toString() ?? '0') ?? 0.0;
    final unrealizedPlpc = double.tryParse(position['unrealizedPlpc']?.toString() ?? '0') ?? 0.0;
    
    final isProfit = unrealizedPl >= 0;
    final profitColor = isProfit ? AppColors.chartRed : AppColors.chartBlue;
    final plpcPercent = unrealizedPlpc * 100;
    final plpcText = plpcPercent >= 0 
        ? '+${plpcPercent.toStringAsFixed(1)}%'
        : '${plpcPercent.toStringAsFixed(1)}%';
    
    // Calculate total return in KRW if exchange rate is available
    String returnText = _formatPriceWithKrw(unrealizedPl, showUsd: false);

    // Format quantity to remove trailing zeros
    final quantityStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(24), vertical: context.h(24)),
      child: Column(
        children: [
          _buildInfoRow('보유 수량', '${quantityStr}주'),
          SizedBox(height: context.h(16)),
          _buildInfoRow('총 금액', _formatPriceWithKrw(marketValue, showUsd: false)),
          SizedBox(height: context.h(16)),
          _buildInfoRow('투자 원금', _formatPriceWithKrw(costBasis, showUsd: false)),
          SizedBox(height: context.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '수익금',
                style: AppFonts.b2Regular.copyWith(color: AppColors.gray600),
              ),
              Row(
                children: [
                  Text(
                    returnText,
                    style: AppFonts.b1Semibold.copyWith(color: profitColor),
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    '($plpcText)',
                    style: AppFonts.b1Semibold.copyWith(color: profitColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistorySection() {
    // Limit to 5 items
    final displayHistory = _orderHistory != null && _orderHistory!.length > 5 
        ? _orderHistory!.sublist(0, 5) 
        : _orderHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(24)),
          child: Text(
            '주문 내역',
            style: AppFonts.b1Semibold.copyWith(
              color: AppColors.gray900,
              fontSize: context.f(18),
            ),
          ),
        ),
        SizedBox(height: context.h(24)), // Increased spacing below title
        if (displayHistory == null || displayHistory.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(24)),
            child: Text(
              '주문 내역이 없습니다.',
              style: AppFonts.b2Regular.copyWith(color: AppColors.gray600),
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                itemCount: displayHistory.length,
                separatorBuilder: (context, index) => SizedBox(height: context.h(32)),
                itemBuilder: (context, index) {
                  return _buildOrderItem(displayHistory[index]);
                },
              ),
              if (_orderHistory != null && _orderHistory!.length > 5) ...[
                SizedBox(height: context.h(40)), // Increased spacing above button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                  child: BigBlackButton(
                    text: '전체 내역 조회', // Changed text
                    onPressed: () {
                      context.push('/order-history?symbol=${Uri.encodeComponent(widget.symbol)}'); // Added encoding
                    },
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final createdAt = order['createdAt'] as String?;
    final side = order['side'] as String?;
    final quantity = order['quantity'] ?? order['filledQuantity'];
    final price = order['filledAvgPrice'] ?? order['limitPrice'];
    
    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {}
    }
    
    final dateStr = date != null ? DateFormat('M.dd').format(date) : '-';
    final typeStr = side == 'buy' ? '구매' : '판매';
    
    // Format quantity to remove trailing zeros
    final qtyVal = quantity is String ? double.tryParse(quantity) : (quantity as num?)?.toDouble();
    final qtyStr = qtyVal != null 
        ? (qtyVal % 1 == 0 ? qtyVal.toInt().toString() : qtyVal.toString()) 
        : '-';
    
    final priceVal = price is String ? double.tryParse(price) : (price as num?)?.toDouble();
    final priceStr = priceVal != null ? _formatPriceWithKrw(priceVal, showUsd: false) : '-';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: context.w(40), // Fixed width for date alignment
          child: Text(
            dateStr,
            style: AppFonts.b2Regular.copyWith(
              color: AppColors.gray600,
              fontSize: context.f(13), // Reduced from 14
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: Text(
              '$typeStr ${qtyStr}주',
              style: AppFonts.b2Regular.copyWith(
                color: AppColors.gray900,
                fontSize: context.f(14), // Reduced from 16
              ),
            ),
          ),
        ),
        Text(
          '주당 $priceStr',
          style: AppFonts.b2Regular.copyWith(
            color: AppColors.gray900,
            fontSize: context.f(13), // Reduced from 14
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.b2Regular.copyWith(color: AppColors.gray600),
        ),
        Text(
          value,
          style: AppFonts.b1Semibold.copyWith(color: AppColors.gray900),
        ),
      ],
    );
  }

  String _formatPriceWithKrw(double price, {bool showUsd = true}) {
    try {
      final dollarFormatted = NumberFormat('#,##0.00').format(price);
      
      if (_exchangeRate != null) {
        final krwValue = price * _exchangeRate!;
        final krwFormatted = NumberFormat('#,###').format(krwValue.round());
        if (showUsd) {
          return '\$$dollarFormatted (${krwFormatted}원)';
        } else {
          return '${krwFormatted}원';
        }
      }
      
      return '\$$dollarFormatted';
    } catch (e) {
      return '\$0.00';
    }
  }
}
