/// 포트폴리오 오버뷰 API 응답 모델
class PortfolioOverviewResponse {
  final Summary summary; // 현재 자산 요약 정보
  final List<HistoryPoint> history; // 자산 변동 이력 데이터
  final double baseValue; // 기준 자산 가치
  final String timeframe; // 조회 기간 (예: "1D", "1M")
  final String fetchedAt; // 데이터 조회 시각

  PortfolioOverviewResponse({
    required this.summary,
    required this.history,
    required this.baseValue,
    required this.timeframe,
    required this.fetchedAt,
  });

  factory PortfolioOverviewResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioOverviewResponse(
      summary: Summary.fromJson(json['summary'] as Map<String, dynamic>),
      history: (json['history'] as List)
          .map((item) => HistoryPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      baseValue: (json['baseValue'] as num).toDouble(),
      timeframe: json['timeframe'] as String,
      fetchedAt: json['fetchedAt'] as String,
    );
  }
}

/// 현재 자산 요약 정보
class Summary {
  final double? equity; // 자본금
  final double? cash; // 현금 잔액
  final double? portfolioValue; // 포트폴리오 총 가치
  final double? buyingPower; // 구매 가능 금액

  Summary({
    this.equity,
    this.cash,
    this.portfolioValue,
    this.buyingPower,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      equity: json['equity'] != null ? (json['equity'] as num).toDouble() : null,
      cash: json['cash'] != null ? (json['cash'] as num).toDouble() : null,
      portfolioValue: json['portfolioValue'] != null ? (json['portfolioValue'] as num).toDouble() : null,
      buyingPower: json['buyingPower'] != null ? (json['buyingPower'] as num).toDouble() : null,
    );
  }
}

/// 자산 변동 이력 데이터 포인트
class HistoryPoint {
  final int timestamp; // 타임스탬프 (밀리초)
  final double equity; // 해당 시점의 자산 가치
  final double profitLoss; // 손익 금액
  final double profitLossPercent; // 손익률 (%)

  HistoryPoint({
    required this.timestamp,
    required this.equity,
    required this.profitLoss,
    required this.profitLossPercent,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      timestamp: json['timestamp'] as int,
      equity: (json['equity'] as num).toDouble(),
      profitLoss: (json['profitLoss'] as num).toDouble(),
      profitLossPercent: (json['profitLossPercent'] as num).toDouble(),
    );
  }
}

