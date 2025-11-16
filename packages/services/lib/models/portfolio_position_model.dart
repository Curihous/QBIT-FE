class PortfolioPosition {
  final String symbol;
  final String quantity;
  final String avgEntryPrice;
  final String marketValue;
  final String costBasis;
  final String unrealizedPl;
  final String unrealizedPlpc;
  final String currentPrice;
  final String side;

  PortfolioPosition({
    required this.symbol,
    required this.quantity,
    required this.avgEntryPrice,
    required this.marketValue,
    required this.costBasis,
    required this.unrealizedPl,
    required this.unrealizedPlpc,
    required this.currentPrice,
    required this.side,
  });

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as String,
      avgEntryPrice: json['avgEntryPrice'] as String,
      marketValue: json['marketValue'] as String,
      costBasis: json['costBasis'] as String,
      unrealizedPl: json['unrealizedPl'] as String,
      unrealizedPlpc: json['unrealizedPlpc'] as String,
      currentPrice: json['currentPrice'] as String,
      side: json['side'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'avgEntryPrice': avgEntryPrice,
      'marketValue': marketValue,
      'costBasis': costBasis,
      'unrealizedPl': unrealizedPl,
      'unrealizedPlpc': unrealizedPlpc,
      'currentPrice': currentPrice,
      'side': side,
    };
  }
}

class PortfolioPositionPageResponse {
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final List<PortfolioPosition> content;

  PortfolioPositionPageResponse({
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.content,
  });

  factory PortfolioPositionPageResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioPositionPageResponse(
      currentPage: json['currentPage'] as int,
      pageSize: json['pageSize'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      hasNext: json['hasNext'] as bool,
      content: (json['content'] as List)
          .map((item) => PortfolioPosition.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'pageSize': pageSize,
      'totalElements': totalElements,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'content': content.map((item) => item.toJson()).toList(),
    };
  }
}

