/// 거래 관련 모델들

/// 주식 정보 모델
class Stock {
  final String symbol;
  final String name;
  final double currentPrice;
  final double changeAmount;
  final double changePercent;
  final int volume;
  final double marketCap;

  const Stock({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.volume,
    required this.marketCap,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      volume: json['volume'] as int,
      marketCap: (json['marketCap'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'changeAmount': changeAmount,
      'changePercent': changePercent,
      'volume': volume,
      'marketCap': marketCap,
    };
  }

  @override
  String toString() {
    return 'Stock(symbol: $symbol, name: $name, currentPrice: $currentPrice)';
  }
}

/// 포트폴리오 모델
class Portfolio {
  final String id;
  final String userId;
  final double totalValue;
  final double totalGainLoss;
  final double totalGainLossPercent;
  final List<PortfolioItem> items;
  final DateTime lastUpdated;

  const Portfolio({
    required this.id,
    required this.userId,
    required this.totalValue,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.items,
    required this.lastUpdated,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'] as String,
      userId: json['userId'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalGainLoss: (json['totalGainLoss'] as num).toDouble(),
      totalGainLossPercent: (json['totalGainLossPercent'] as num).toDouble(),
      items: (json['items'] as List)
          .map((item) => PortfolioItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'totalValue': totalValue,
      'totalGainLoss': totalGainLoss,
      'totalGainLossPercent': totalGainLossPercent,
      'items': items.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// 포트폴리오 아이템 모델
class PortfolioItem {
  final String stockSymbol;
  final String stockName;
  final int quantity;
  final double averagePrice;
  final double currentPrice;
  final double totalValue;
  final double gainLoss;
  final double gainLossPercent;

  const PortfolioItem({
    required this.stockSymbol,
    required this.stockName,
    required this.quantity,
    required this.averagePrice,
    required this.currentPrice,
    required this.totalValue,
    required this.gainLoss,
    required this.gainLossPercent,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      stockSymbol: json['stockSymbol'] as String,
      stockName: json['stockName'] as String,
      quantity: json['quantity'] as int,
      averagePrice: (json['averagePrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      gainLoss: (json['gainLoss'] as num).toDouble(),
      gainLossPercent: (json['gainLossPercent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockSymbol': stockSymbol,
      'stockName': stockName,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'totalValue': totalValue,
      'gainLoss': gainLoss,
      'gainLossPercent': gainLossPercent,
    };
  }
}
