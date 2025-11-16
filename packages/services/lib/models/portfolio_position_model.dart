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
    final symbol = json['symbol']?.toString();
    if (symbol == null) {
      throw FormatException('Missing required field: symbol', json);
    }
    
    final quantity = json['quantity']?.toString();
    if (quantity == null) {
      throw FormatException('Missing required field: quantity', json);
    }
    
    final avgEntryPrice = json['avgEntryPrice']?.toString();
    if (avgEntryPrice == null) {
      throw FormatException('Missing required field: avgEntryPrice', json);
    }
    
    final marketValue = json['marketValue']?.toString();
    if (marketValue == null) {
      throw FormatException('Missing required field: marketValue', json);
    }
    
    final costBasis = json['costBasis']?.toString();
    if (costBasis == null) {
      throw FormatException('Missing required field: costBasis', json);
    }
    
    final unrealizedPl = json['unrealizedPl']?.toString();
    if (unrealizedPl == null) {
      throw FormatException('Missing required field: unrealizedPl', json);
    }
    
    final unrealizedPlpc = json['unrealizedPlpc']?.toString();
    if (unrealizedPlpc == null) {
      throw FormatException('Missing required field: unrealizedPlpc', json);
    }
    
    final currentPrice = json['currentPrice']?.toString();
    if (currentPrice == null) {
      throw FormatException('Missing required field: currentPrice', json);
    }
    
    final side = json['side']?.toString();
    if (side == null) {
      throw FormatException('Missing required field: side', json);
    }
    
    return PortfolioPosition(
      symbol: symbol,
      quantity: quantity,
      avgEntryPrice: avgEntryPrice,
      marketValue: marketValue,
      costBasis: costBasis,
      unrealizedPl: unrealizedPl,
      unrealizedPlpc: unrealizedPlpc,
      currentPrice: currentPrice,
      side: side,
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

    final currentPage = json['currentPage'] as int?;
    if (currentPage == null) {
      throw FormatException('Missing required field: currentPage', json);
    }
    
    final pageSize = json['pageSize'] as int?;
    if (pageSize == null) {
      throw FormatException('Missing required field: pageSize', json);
    }
    
    final totalElements = json['totalElements'] as int?;
    if (totalElements == null) {
      throw FormatException('Missing required field: totalElements', json);
    }
    
    final totalPages = json['totalPages'] as int?;
    if (totalPages == null) {
      throw FormatException('Missing required field: totalPages', json);
    }
    
    final hasNext = json['hasNext'] as bool?;
    if (hasNext == null) {
      throw FormatException('Missing required field: hasNext', json);
    }
    
    return PortfolioPositionPageResponse(
      currentPage: currentPage,
      pageSize: pageSize,
      totalElements: totalElements,
      totalPages: totalPages,
      hasNext: hasNext,
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

