import 'package:flutter/material.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

class VerticalOrderBookWidget extends StatefulWidget {
  final String symbol;
  final OrderBookModel? orderBook;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const VerticalOrderBookWidget({
    super.key,
    required this.symbol,
    this.orderBook,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<VerticalOrderBookWidget> createState() => _VerticalOrderBookWidgetState();
}

class _VerticalOrderBookWidgetState extends State<VerticalOrderBookWidget> {
  OrderBookEntry? _selectedEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 호가창 내용
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.orderBook == null
                    ? _buildEmptyState()
                    : _buildVerticalOrderBook(),
          ),
          
          // 체결 강도
          if (widget.orderBook != null) ...[
            const SizedBox(height: 16),
            _buildExecutionStrength(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            '호가창 데이터가 없습니다',
            style: AppFonts.b1Regular.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalOrderBook() {
    final orderBook = widget.orderBook!;
    
    // 매수와 매도를 합쳐서 세로로 나열 (매도 위, 매수 아래)
    final allEntries = <_OrderBookEntry>[];
    
    // 매도 호가 (가격 높은 순으로 위쪽에)
    for (int i = orderBook.asks.length - 1; i >= 0; i--) {
      allEntries.add(_OrderBookEntry(orderBook.asks[i], false));
    }
    
    // 매수 호가 (가격 높은 순으로 아래쪽에)
    for (int i = 0; i < orderBook.bids.length; i++) {
      allEntries.add(_OrderBookEntry(orderBook.bids[i], true));
    }
    
    return ListView.builder(
      itemCount: allEntries.length,
      itemBuilder: (context, index) {
        final entry = allEntries[index];
        final isSelected = _selectedEntry == entry.orderBookEntry;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEntry = entry.orderBookEntry;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // 왼쪽: 가격 (1:1 비율)
                Expanded(
                  child: Center(
                    child: Text(
                      _formatPrice(entry.orderBookEntry.price),
                      style: AppFonts.b2Regular.copyWith(
                        color: entry.isBid ? AppColors.profit : AppColors.loss,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                // 오른쪽: 막대 (1:1 비율)
                Expanded(
                  child: Center(
                    child: Container(
                      height: 32,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: entry.isBid 
                            ? AppColors.orderBookBidBg
                            : AppColors.orderBookAskBg,
                        border: isSelected 
                            ? Border.all(
                                color: entry.isBid ? AppColors.profit : AppColors.loss, 
                                width: 1)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          _formatQuantity(entry.orderBookEntry.quantity),
                          style: AppFonts.b2Regular.copyWith(
                            color: AppColors.gray900,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutionStrength() {
    // 체결 강도 계산 (매수량 / 매도량 * 100)
    final orderBook = widget.orderBook!;
    final totalBidQuantity = orderBook.bids.fold(0.0, (sum, bid) => sum + bid.quantity);
    final totalAskQuantity = orderBook.asks.fold(0.0, (sum, ask) => sum + ask.quantity);
    
    double executionStrength = 0.0;
    if (totalAskQuantity > 0) {
      executionStrength = (totalBidQuantity / totalAskQuantity) * 100;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '체결 강도',
            style: AppFonts.b2Regular.copyWith(color: AppColors.gray600),
          ),
          Text(
            '${executionStrength.toStringAsFixed(2)}%',
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray900),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }

  String _formatQuantity(double quantity) {
    if (quantity >= 1000) {
      return '${(quantity / 1000).toStringAsFixed(1)}K';
    } else if (quantity >= 1) {
      return quantity.toStringAsFixed(2);
    } else {
      return quantity.toStringAsFixed(6);
    }
  }
}

class _OrderBookEntry {
  final OrderBookEntry orderBookEntry;
  final bool isBid;

  _OrderBookEntry(this.orderBookEntry, this.isBid);
}
