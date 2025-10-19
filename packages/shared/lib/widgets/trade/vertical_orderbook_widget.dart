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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          
          // 체결 강도는 상단으로 이동됨
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
    
    // 최대 수량 계산 (사각형 크기 비율 계산용)
    double maxQuantity = 0.0;
    for (final entry in allEntries) {
      if (entry.orderBookEntry.quantity > maxQuantity) {
        maxQuantity = entry.orderBookEntry.quantity;
      }
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
            padding: const EdgeInsets.only(left: 0, right: 0),
            child: Row(
              children: [
                // 왼쪽: 가격 (체결강도 블록과 같은 시작점에 맞춤)
                Padding(
                  padding: const EdgeInsets.only(left: 4), // 아주 살짝만 오른쪽으로
                  child: Text(
                    _formatPrice(entry.orderBookEntry.price),
                    style: AppFonts.b2Semibold.copyWith(
                      color: entry.isBid ? AppColors.profit : AppColors.loss,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                // 중간: 여백 (텍스트들 사이 간격 늘리기)
                const SizedBox(width: 20),
                // 오른쪽: 텍스트와 사각형 (사각형 우측 정렬)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = maxQuantity > 0 
                          ? ((entry.orderBookEntry.quantity / maxQuantity) * 40.0 + 20.0).clamp(20.0, 60.0)
                          : 20.0;
                      
                      final textWidth = _getTextWidth(_formatQuantity(entry.orderBookEntry.quantity));
                      final availableWidth = constraints.maxWidth;
                      
                      // 토스 스타일: 텍스트를 사각형 안에 넣을지 밖에 넣을지 결정
                      final showTextInside = textWidth + 4 <= barWidth; // 텍스트가 사각형 안에 들어갈 수 있으면
                      
                      return Stack(
                        children: [
                          // 사각형 막대 (오른쪽 끝 고정, 왼쪽으로 확장)
                          Positioned(
                            right: 0,
                            top: 6,
                            child: Container(
                              height: 32,
                              width: barWidth,
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
                            ),
                          ),
                          // 텍스트 (토스 스타일: 사각형 크기에 따라 안/밖 배치)
                          if (showTextInside)
                            // 텍스트가 사각형 안에 들어가는 경우
                            Positioned(
                              right: 4,
                              top: 0,
                              child: Container(
                                height: 44,
                                width: barWidth - 4,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatQuantity(entry.orderBookEntry.quantity),
                                  style: AppFonts.c2.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                ),
                              ),
                            )
                          else
                            // 텍스트가 사각형 밖에 표시되는 경우
                            Positioned(
                              right: barWidth + 2,
                              top: 0,
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  _formatQuantity(entry.orderBookEntry.quantity),
                                  style: AppFonts.c2.copyWith(
                                    color: AppColors.gray900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            style: AppFonts.b2Semibold.copyWith(color: AppColors.gray600),
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

  double _getTextWidth(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppFonts.c2,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}

class _OrderBookEntry {
  final OrderBookEntry orderBookEntry;
  final bool isBid;

  _OrderBookEntry(this.orderBookEntry, this.isBid);
}
