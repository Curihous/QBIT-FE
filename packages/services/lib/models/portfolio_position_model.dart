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
    String requireString(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException('Missing required field: $key', json);
      }
      return value.toString();
    }

    return PortfolioPosition(
      symbol: requireString('symbol'),
      quantity: requireString('quantity'),
      avgEntryPrice: requireString('avgEntryPrice'),
      marketValue: requireString('marketValue'),
      costBasis: requireString('costBasis'),
      unrealizedPl: requireString('unrealizedPl'),
      unrealizedPlpc: requireString('unrealizedPlpc'),
      currentPrice: requireString('currentPrice'),
      side: requireString('side'),
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

    int requireInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      throw FormatException('Missing or invalid field: $key', json);
    }

    bool requireBool(String key) {
      final value = json[key];
      if (value is bool) return value;
      throw FormatException('Missing or invalid field: $key', json);
    }

    return PortfolioPositionPageResponse(
      currentPage: requireInt('currentPage'),
      pageSize: requireInt('pageSize'),
      totalElements: requireInt('totalElements'),
      totalPages: requireInt('totalPages'),
      hasNext: requireBool('hasNext'),
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

