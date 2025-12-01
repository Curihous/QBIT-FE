class OrderHistoryModel {
  final int orderId;
  final String alpacaOrderId;
  final String symbol;
  final String side; // "buy" or "sell"
  final String quantity;
  final String filledQuantity;
  final String? filledAvgPrice;
  final String type; // "market" or "limit"
  final String timeInForce;
  final String? limitPrice;
  final String? stopPrice;
  final String status; // "pending_new", "accepted", "filled", etc.
  final String createdAt;
  final String submittedAt;
  final String? filledAt;
  final String? canceledAt;
  final String? replacedAt;
  final String? replacedBy;
  final String? replaces;
  final String? logoUrl;

  OrderHistoryModel({
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
    this.logoUrl,
  });

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel(
      orderId: json['orderId'] ?? 0,
      alpacaOrderId: json['alpacaOrderId'] ?? '',
      symbol: json['symbol'] ?? '',
      side: json['side'] ?? '',
      quantity: json['quantity'] ?? '0',
      filledQuantity: json['filledQuantity'] ?? '0',
      filledAvgPrice: json['filledAvgPrice'],
      type: json['type'] ?? '',
      timeInForce: json['timeInForce'] ?? '',
      limitPrice: json['limitPrice'],
      stopPrice: json['stopPrice'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
      filledAt: json['filledAt'],
      canceledAt: json['canceledAt'],
      replacedAt: json['replacedAt'],
      replacedBy: json['replacedBy'],
      replaces: json['replaces'],
      logoUrl: json['logoUrl'],
    );
  }

  // 상태를 한국어로 변환 (알파카 기준)
  String get statusInKorean {
    switch (status.toUpperCase()) {
      case 'NEW':
        return '새 주문';
      case 'PENDING_NEW':
        return '주문 접수';
      case 'ACCEPTED':
        return '주문 접수';
      case 'PARTIALLY_FILLED':
        return side == 'buy' ? '부분 구매' : '부분 매도';
      case 'FILLED':
        return side == 'buy' ? '구매 완료' : '매도 완료';
      case 'DONE_FOR_DAY':
        return '당일 거래 종료';
      case 'CANCELED':
        return '주문 취소';
      case 'EXPIRED':
        return '주문 만료';
      case 'REPLACED':
        return '주문 대체';
      case 'PENDING_CANCEL':
        return '취소 대기';
      case 'PENDING_REPLACE':
        return '대체 대기';
      case 'REJECTED':
        return '주문 거부';
      case 'SUSPENDED':
        return '주문 중지';
      case 'CALCULATED':
        return '계산 완료';
      default:
        return '주문 접수';
    }
  }

  // 사이드를 한국어로 변환
  String get sideInKorean {
    return side == 'buy' ? '매수' : '매도';
  }

  // 주문 타입을 한국어로 변환
  String get typeInKorean {
    return type == 'market' ? '시장가' : '지정가';
  }

  // 날짜를 MM.DD 형식으로 변환
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00.00';
    }
  }

  // 수량과 가격 정보를 포맷팅 (줄바꿈 방지)
  String get formattedQuantityAndPrice {
    final qty = double.tryParse(quantity) ?? 0.0;
    final formattedQty = qty == qty.toInt() ? qty.toInt().toString() : qty.toString();
    
    if (type == 'market') {
      if (filledAvgPrice != null && filledAvgPrice!.isNotEmpty) {
        final price = double.tryParse(filledAvgPrice!) ?? 0.0;
        return '${formattedQty}주 · \$${price.toStringAsFixed(2)}';
      } else {
        return '${formattedQty}주 · 시장가';
      }
    } else {
      if (limitPrice != null && limitPrice!.isNotEmpty) {
        final price = double.tryParse(limitPrice!) ?? 0.0;
        return '${formattedQty}주 · 지정가 \$${price.toStringAsFixed(2)}';
      } else {
        return '${formattedQty}주 · 지정가';
      }
    }
  }

  // 수량만 포맷팅
  String get formattedQuantity {
    final qty = double.tryParse(quantity) ?? 0.0;
    return qty == qty.toInt() ? '${qty.toInt()}주' : '${qty}주';
  }

  // 가격만 포맷팅
  String get formattedPrice {
    if (type == 'market') {
      if (filledAvgPrice != null && filledAvgPrice!.isNotEmpty) {
        final price = double.tryParse(filledAvgPrice!) ?? 0.0;
        return '\$${price.toStringAsFixed(2)}';
      } else {
        return '시장가';
      }
    } else {
      if (limitPrice != null && limitPrice!.isNotEmpty) {
        final price = double.tryParse(limitPrice!) ?? 0.0;
        return '지정가 \$${price.toStringAsFixed(2)}';
      } else {
        return '지정가';
      }
    }
  }
}

class OrderHistoryResponse {
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final List<OrderHistoryModel> content;

  OrderHistoryResponse({
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.content,
  });

  factory OrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResponse(
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => OrderHistoryModel.fromJson(item))
          .toList() ?? [],
    );
  }
}
