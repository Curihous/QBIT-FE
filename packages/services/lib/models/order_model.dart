class OrderModel {
  final String symbol;
  final String quantity;
  final String side; // 'buy' or 'sell'
  final String type; // 'market' or 'limit'
  final String timeInForce; // 'day', 'gtc', 'ioc', 'fok'
  final String? limitPrice;
  final String? stopPrice;
  
  // 추가 필드들 (API 응답용)
  final String? orderId;
  final String? status;
  final String? filledQuantity;
  final String? filledAvgPrice;
  final String? createdAt;
  final String? filledAt;

  OrderModel({
    required this.symbol,
    required this.quantity,
    required this.side,
    required this.type,
    required this.timeInForce,
    this.limitPrice,
    this.stopPrice,
    this.orderId,
    this.status,
    this.filledQuantity,
    this.filledAvgPrice,
    this.createdAt,
    this.filledAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'symbol': symbol,
      'quantity': quantity,
      'side': side,
      'type': type,
      'timeInForce': timeInForce,
    };

    if (limitPrice != null) {
      data['limitPrice'] = limitPrice;
    }
    if (stopPrice != null) {
      data['stopPrice'] = stopPrice;
    }

    return data;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      symbol: json['symbol'] ?? '',
      quantity: json['quantity'] ?? '',
      side: json['side'] ?? '',
      type: json['type'] ?? '',
      timeInForce: json['timeInForce'] ?? '',
      limitPrice: json['limitPrice'],
      stopPrice: json['stopPrice'],
      orderId: json['orderId'] ?? json['id'],
      status: json['status'],
      filledQuantity: json['filledQuantity'] ?? json['filled_qty'],
      filledAvgPrice: json['filledAvgPrice'] ?? json['filled_avg_price'],
      createdAt: json['createdAt'] ?? json['created_at'],
      filledAt: json['filledAt'] ?? json['filled_at'],
    );
  }

  // 편의 메서드들
  double get quantityAsDouble => double.tryParse(quantity) ?? 0.0;
  double get limitPriceAsDouble => double.tryParse(limitPrice ?? '0') ?? 0.0;
  double get stopPriceAsDouble => double.tryParse(stopPrice ?? '0') ?? 0.0;
  
  // 사이드 표시명
  String get sideDisplayName => side == 'buy' ? '매수' : '매도';
  
  // 타입 표시명
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'market': return '시장가';
      case 'limit': return '지정가';
      case 'stop': return '스탑';
      case 'stop_limit': return '스탑지정가';
      default: return type;
    }
  }
  
  // 유효기간 표시명
  String get timeInForceDisplayName {
    switch (timeInForce.toLowerCase()) {
      case 'day': return '당일';
      case 'gtc': return '지정일까지';
      case 'ioc': return '즉시체결';
      case 'fok': return '전량체결';
      default: return timeInForce;
    }
  }

  @override
  String toString() {
    return 'OrderModel(symbol: $symbol, quantity: $quantity, side: $side, type: $type, timeInForce: $timeInForce, limitPrice: $limitPrice, stopPrice: $stopPrice, orderId: $orderId, status: $status)';
  }
}