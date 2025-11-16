/// 거래 사이클 응답 모델
class TradeCycleResponseDto {
  final int tradeCycleId;
  final String symbol;
  final String? logoUrl;
  final DateTime startDate;
  final DateTime? endDate; // nullable
  final double profitLossRate;
  final double profitLossAmount;

  TradeCycleResponseDto({
    required this.tradeCycleId,
    required this.symbol,
    this.logoUrl,
    required this.startDate,
    this.endDate, // nullable
    required this.profitLossRate,
    required this.profitLossAmount,
  });

  factory TradeCycleResponseDto.fromJson(Map<String, dynamic> json) {
    return TradeCycleResponseDto(
      tradeCycleId: json['tradeCycleId'] as int,
      symbol: json['symbol'] as String,
      logoUrl: json['logoUrl'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      profitLossRate: (json['profitLossRate'] as num).toDouble(),
      profitLossAmount: (json['profitLossAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tradeCycleId': tradeCycleId,
      'symbol': symbol,
      'logoUrl': logoUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'profitLossRate': profitLossRate,
      'profitLossAmount': profitLossAmount,
    };
  }
}

/// 거래 사이클 페이지네이션 응답 모델
class TradeCyclePageResponse {
  final int currentPage;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final List<TradeCycleResponseDto> content;

  TradeCyclePageResponse({
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.content,
  });

  factory TradeCyclePageResponse.fromJson(Map<String, dynamic> json) {
    return TradeCyclePageResponse(
      currentPage: json['currentPage'] as int,
      pageSize: json['pageSize'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      hasNext: json['hasNext'] as bool,
      content: (json['content'] as List)
          .map((item) => TradeCycleResponseDto.fromJson(item as Map<String, dynamic>))
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

