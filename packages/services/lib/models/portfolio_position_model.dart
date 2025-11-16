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
      symbol: json['symbol']?.toString() ??
          throw FormatException('Missing required field: symbol', json),
      quantity: json['quantity']?.toString() ??
          throw FormatException('Missing required field: quantity', json),
      avgEntryPrice: json['avgEntryPrice']?.toString() ??
          throw FormatException('Missing required field: avgEntryPrice', json),
      marketValue: json['marketValue']?.toString() ??
          throw FormatException('Missing required field: marketValue', json),
      costBasis: json['costBasis']?.toString() ??
          throw FormatException('Missing required field: costBasis', json),
      unrealizedPl: json['unrealizedPl']?.toString() ??
          throw FormatException('Missing required field: unrealizedPl', json),
      unrealizedPlpc: json['unrealizedPlpc']?.toString() ??
          throw FormatException('Missing required field: unrealizedPlpc', json),
      currentPrice: json['currentPrice']?.toString() ??
          throw FormatException('Missing required field: currentPrice', json),
      side: json['side']?.toString() ??
          throw FormatException('Missing required field: side', json),
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
    final contentValue = json['content'];
    if (contentValue == null) {
      throw FormatException('Missing required field: content', json);
    }
    if (contentValue is! List) {
      throw FormatException(
          'Invalid type for field content: expected List, got ${contentValue.runtimeType}',
          json);
    }

    return PortfolioPositionPageResponse(
      currentPage: json['currentPage'] as int? ??
          throw FormatException('Missing required field: currentPage', json),
      pageSize: json['pageSize'] as int? ??
          throw FormatException('Missing required field: pageSize', json),
      totalElements: json['totalElements'] as int? ??
          throw FormatException('Missing required field: totalElements', json),
      totalPages: json['totalPages'] as int? ??
          throw FormatException('Missing required field: totalPages', json),
      hasNext: json['hasNext'] as bool? ??
          throw FormatException('Missing required field: hasNext', json),
      content: contentValue
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException(
                  'Invalid content item type: expected Map<String, dynamic>, got ${item.runtimeType}',
                  item);
            }
            return PortfolioPosition.fromJson(item);
          })
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

