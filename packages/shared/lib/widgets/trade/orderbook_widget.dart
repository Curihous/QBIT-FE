import 'package:flutter/material.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';

class OrderBookWidget extends StatefulWidget {
  final String symbol;
  final OrderBookModel? orderBook;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const OrderBookWidget({
    super.key,
    required this.symbol,
    this.orderBook,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<OrderBookWidget> createState() => _OrderBookWidgetState();
}

class _OrderBookWidgetState extends State<OrderBookWidget> {
  OrderBookEntry? _selectedBid;
  OrderBookEntry? _selectedAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '호가창',
                style: AppFonts.t2Bold.copyWith(color: AppColors.gray900),
              ),
              if (widget.onRefresh != null)
                GestureDetector(
                  onTap: widget.onRefresh,
                  child: Icon(
                    Icons.refresh,
                    color: AppColors.gray600,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 호가창 내용
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.orderBook == null
                    ? _buildEmptyState()
                    : _buildOrderBook(),
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

  Widget _buildOrderBook() {
    final orderBook = widget.orderBook!;
    
    return Row(
      children: [
        // 매수 호가 (왼쪽)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '매수',
                style: AppFonts.b2Semibold.copyWith(color: AppColors.profit),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: orderBook.bids.length,
                  itemBuilder: (context, index) {
                    final bid = orderBook.bids[index];
                    final isSelected = _selectedBid == bid;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBid = bid;
                          _selectedAsk = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.profit.withOpacity(0.1)
                              : AppColors.profit.withOpacity(0.05),
                          border: isSelected 
                              ? Border.all(color: AppColors.profit, width: 1)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPrice(bid.price),
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.profit,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Text(
                              _formatQuantity(bid.quantity),
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.gray900,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // 매도 호가 (오른쪽)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '매도',
                style: AppFonts.b2Semibold.copyWith(color: AppColors.loss),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: orderBook.asks.length,
                  itemBuilder: (context, index) {
                    final ask = orderBook.asks[index];
                    final isSelected = _selectedAsk == ask;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAsk = ask;
                          _selectedBid = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.loss.withOpacity(0.1)
                              : AppColors.loss.withOpacity(0.05),
                          border: isSelected 
                              ? Border.all(color: AppColors.loss, width: 1)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatPrice(ask.price),
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.loss,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Text(
                              _formatQuantity(ask.quantity),
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.gray900,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
