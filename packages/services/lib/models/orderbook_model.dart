class OrderBookModel {
  final List<OrderBookEntry> bids;
  final List<OrderBookEntry> asks;
  final DateTime timestamp;

  OrderBookModel({
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  factory OrderBookModel.fromJson(Map<String, dynamic> json) {
    return OrderBookModel(
      bids: (json['bids'] as List<dynamic>?)
              ?.map((e) => OrderBookEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      asks: (json['asks'] as List<dynamic>?)
              ?.map((e) => OrderBookEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bids': bids.map((e) => e.toJson()).toList(),
      'asks': asks.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class OrderBookEntry {
  final double price;
  final double quantity;
  final double? changePercentage;

  OrderBookEntry({
    required this.price,
    required this.quantity,
    this.changePercentage,
  });

  factory OrderBookEntry.fromJson(Map<String, dynamic> json) {
    return OrderBookEntry(
      price: _parseDouble(json['price']),
      quantity: _parseDouble(json['quantity']),
      changePercentage: json['changePercentage'] != null 
          ? _parseDouble(json['changePercentage']) 
          : null,
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'quantity': quantity,
      if (changePercentage != null) 'changePercentage': changePercentage,
    };
  }

  double get total => price * quantity;
}
