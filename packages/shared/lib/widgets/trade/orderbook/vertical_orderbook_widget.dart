import 'dart:ui'; // For FontFeature

import 'package:flutter/material.dart';

import 'package:qbit_services/models/orderbook_model.dart';

import 'package:qbit_shared/theme/app_colors.dart';

import 'package:qbit_shared/theme/app_fonts.dart';

import 'package:intl/intl.dart';

class VerticalOrderBookWidget extends StatefulWidget {
  final String symbol;
  final OrderBookModel? orderBook;
  final Map<String, dynamic>? quote;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const VerticalOrderBookWidget({
    super.key,
    required this.symbol,
    this.orderBook,
    this.quote,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<VerticalOrderBookWidget> createState() => _VerticalOrderBookWidgetState();
}

class _VerticalOrderBookWidgetState extends State<VerticalOrderBookWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialScrollDone = false;

  // 상수 정의
  static const double _itemHeight = 40.0; // 행 높이
  static const int _flexLeft = 4;
  static const int _flexCenter = 3;
  static const int _flexRight = 4;

  @override
  void didUpdateWidget(VerticalOrderBookWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 데이터가 처음 로드되었을 때 중간으로 스크롤
    if (widget.orderBook != null && oldWidget.orderBook == null && !_isInitialScrollDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCenter();
      });
    }
  }

  void _scrollToCenter() {
    if (!_scrollController.hasClients) return;

    // Asks(매도)가 리스트의 앞부분에 위치함
    final asksCount = widget.orderBook?.asks.length ?? 0;

    // Asks의 마지막 부분(Spread 근처)이 화면 중앙에 오도록 스크롤 계산
    final screenHeight = _scrollController.position.viewportDimension;

    // Asks 리스트의 끝부분(최저 매도가)이 화면 중앙보다 약간 위에 오도록
    final scrollOffset = (asksCount * _itemHeight) - (screenHeight / 2) + (_itemHeight * 2);

    _scrollController.jumpTo(scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent));

    _isInitialScrollDone = true;
  }

  // 호가 데이터 처리 함수 (User's logic)
  List<OrderBookEntry> _processOrders(List<OrderBookEntry> rawOrders, bool isAsk) {
    // 1. 같은 가격끼리 합치기 (Map 사용)
    final Map<double, double> aggregated = {};

    for (var order in rawOrders) {
      // 수량이 0에 가까운 데이터는 무시 (부동소수점 오차 고려)
      if (order.quantity < 0.00000001) continue;

      // 가격 정규화: UI 표시 방식과 동일하게 그룹화
      // 화면에 보이는 가격(String)을 기준으로 다시 숫자로 변환하여 Key로 사용
      // 이렇게 해야 "보이는 대로" 합쳐짐 (WYSIWYG)
      double normalizedPrice;
      if (order.price >= 100000) {
        // 10만 이상: 정수 (소수점 버림) - 비트코인 등
        normalizedPrice = order.price.roundToDouble();
      } else if (order.price >= 1000) {
        // 1천 ~ 10만: 소수점 2자리 - 미국 주식, 이더리움 등
        normalizedPrice = double.parse(order.price.toStringAsFixed(2));
      } else {
        // 1천 미만: 소수점 4자리 - 소형 코인, 리플 등
        normalizedPrice = double.parse(order.price.toStringAsFixed(4));
      }

      if (aggregated.containsKey(normalizedPrice)) {
        aggregated[normalizedPrice] = aggregated[normalizedPrice]! + order.quantity;
      } else {
        aggregated[normalizedPrice] = order.quantity;
      }
    }

    // 2. Map을 다시 List로 변환
    List<OrderBookEntry> result = aggregated.entries.map((entry) {
      return OrderBookEntry(price: entry.key, quantity: entry.value);
    }).toList();

    // 3. 정렬
    // 매도(Ask): 비싼 가격 -> 싼 가격 (화면 위 -> 아래)
    // 매수(Bid): 비싼 가격 -> 싼 가격 (화면 위 -> 아래)
    // 둘 다 내림차순 정렬하면 됨
    result.sort((a, b) => b.price.compareTo(a.price));

    return result;
  }

  // ... (build and other methods) ...

  String _formatQuantity(double quantity) {
    if (quantity >= 1000000) return '${(quantity / 1000000).toStringAsFixed(2)}M';
    if (quantity >= 1000) return '${(quantity / 1000).toStringAsFixed(2)}K';

    // 1 미만인 경우 소수점 4자리 (암호화폐 등)
    if (quantity < 1) {
      return quantity.toStringAsFixed(4);
    }

    // 1 ~ 1000 사이: 소수점 4자리로 통일하여 정렬 맞춤 (User Request)
    // 정수라도 1.0000 처럼 보이게
    return quantity.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.orderBook == null) {
      return _buildEmptyState();
    }

    final orderBook = widget.orderBook!;

    // 1. 데이터 정제 (0 제거 및 가격별 합산, 정렬)
    // Asks: High -> Low (화면 상단 -> 하단)
    final asks = _processOrders(orderBook.asks, true);

    // Bids: High -> Low (화면 상단 -> 하단)
    final bids = _processOrders(orderBook.bids, false);

    // 최대 수량 계산 (그래프 비율용)
    double maxQuantity = 0.0;
    for (var ask in asks) if (ask.quantity > maxQuantity) maxQuantity = ask.quantity;
    for (var bid in bids) if (bid.quantity > maxQuantity) maxQuantity = bid.quantity;

    // 전일 종가 (변동률 계산용 - 상단 패널용)
    double prevClose = 0.0;
    if (widget.quote != null) {
      prevClose = _getValue(widget.quote!, ['prevClose', 'x']);
    }
    if (prevClose == 0.0 && widget.quote != null) {
      final current = _getValue(widget.quote!, ['price', 'c']);
      final change = _getValue(widget.quote!, ['change', 'p']);
      prevClose = current - change;
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 1. 시장 정보 패널 (헤더로 이동)
          _buildMarketInfoPanel(prevClose),

          // 2. 호가 리스트
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Asks (매도)
                  ...asks.map((ask) => _buildOrderRow(
                        price: ask.price,
                        quantity: ask.quantity,
                        maxQuantity: maxQuantity,
                        isBid: false,
                        prevClose: prevClose,
                      )),

                  // Bids (매수)
                  ...bids.map((bid) => _buildOrderRow(
                        price: bid.price,
                        quantity: bid.quantity,
                        maxQuantity: maxQuantity,
                        isBid: true,
                        prevClose: prevClose,
                      )),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '호가 데이터 없음',
        style: AppFonts.c1.copyWith(color: AppColors.gray400),
      ),
    );
  }

  // 호가 행 (Row)
  Widget _buildOrderRow({
    required double price,
    required double quantity,
    required double maxQuantity,
    required bool isBid,
    required double prevClose,
  }) {
    // 색상 설정
    // Ask(매도): Blue (AppColors.profit)
    // Bid(매수): Red (AppColors.loss)
    final baseColor = isBid ? AppColors.chartRed : AppColors.chartBlue;
    final bgColor = baseColor.withOpacity(0.03); // 배경색 (아주 연하게)
    final barColor = baseColor.withOpacity(0.15); // 그래프 색상

    return Container(
      height: _itemHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray50)),
      ),
      child: Row(
        children: [
          // [Left] 매도 잔량 (Asks Volume) or Empty (Bids)
          Expanded(
            flex: _flexLeft,
            child: !isBid
                ? _buildVolumeBar(quantity, maxQuantity, barColor, Alignment.centerRight, true)
                : Container(color: bgColor), // 매수일 때는 빈 배경 (Red tint)
          ),

          // [Center] 가격
          Expanded(
            flex: _flexCenter,
            child: _buildPriceCell(price, prevClose, bgColor, isBid),
          ),

          // [Right] 매수 잔량 (Bids Volume) or Empty (Asks)
          Expanded(
            flex: _flexRight,
            child: isBid
                ? _buildVolumeBar(quantity, maxQuantity, barColor, Alignment.centerLeft, false)
                : Container(color: bgColor), // 매도일 때는 빈 배경 (Blue tint)
          ),
        ],
      ),
    );
  }

  // 잔량 그래프 바
  Widget _buildVolumeBar(
    double quantity,
    double maxQuantity,
    Color color,
    Alignment alignment,
    bool isRightAlignText,
  ) {
    return Stack(
      alignment: alignment,
      children: [
        // 1. Bar Graph
        FractionallySizedBox(
          widthFactor: maxQuantity > 0 ? (quantity / maxQuantity).clamp(0.0, 1.0) : 0,
          heightFactor: 1.0,
          child: Container(color: color),
        ),

        // 2. Quantity Text
        Container(
          alignment: isRightAlignText ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _formatQuantity(quantity),
            style: AppFonts.c2.copyWith(
              color: AppColors.gray900,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFeatures: [const FontFeature.tabularFigures()], // 숫자 너비 고정
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // 가격 셀
  Widget _buildPriceCell(double price, double prevClose, Color bgColor, bool isBid) {
    // 가격 색상:
    // Ask(매도) = Blue (AppColors.chartBlue)
    // Bid(매수) = Red (AppColors.chartRed)
    final priceColor = isBid ? AppColors.chartRed : AppColors.chartBlue;

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        _formatPrice(price),
        style: AppFonts.b1Regular.copyWith(
          color: priceColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFeatures: [const FontFeature.tabularFigures()], // 숫자 너비 고정 (춤추는 현상 방지)
        ),
      ),
    );
  }

  // 상단 시장 정보 패널 (헤더 형태)
  Widget _buildMarketInfoPanel(double prevClose) {
    if (widget.quote == null) return const SizedBox();

    final quote = widget.quote!;
    final high = _getValue(quote, ['high', 'h']);
    final low = _getValue(quote, ['low', 'l']);
    final volume = _getValue(quote, ['volume', 'v']);

    // 거래대금은 공간 부족으로 생략하거나 필요시 추가

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem('전일종가', _formatPrice(prevClose), AppColors.gray900),
          _buildInfoItem('고가', _formatPrice(high), AppColors.chartRed),
          _buildInfoItem('저가', _formatPrice(low), AppColors.chartBlue),
          _buildInfoItem('거래량', _formatSimpleQuantity(volume), AppColors.gray600),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppFonts.c2.copyWith(color: AppColors.gray600, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppFonts.c2.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    // Legacy method - kept just in case but not used in new layout
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppFonts.c2.copyWith(color: AppColors.gray600, fontSize: 10),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppFonts.c2.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatSimpleQuantity(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  double _getValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return _parseDouble(map[key]);
      }
    }
    return 0.0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatPrice(double price) {
    if (price >= 100000) {
      // 10만 이상: 정수
      return NumberFormat('#,###').format(price);
    } else if (price >= 1000) {
      // 1천 ~ 10만: 소수점 2자리
      return NumberFormat('#,###.00').format(price);
    } else {
      // 1천 미만: 소수점 4자리
      return price.toStringAsFixed(4);
    }
  }
}
