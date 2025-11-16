class TradeReportIndicator {
  final double value;
  final String analysis;

  TradeReportIndicator({
    required this.value,
    required this.analysis,
  });

  factory TradeReportIndicator.fromJson(Map<String, dynamic> json) {
    return TradeReportIndicator(
      value: (json['value'] as num).toDouble(),
      analysis: json['analysis'] as String,
    );
  }
}

class TradeReportLearningCard {
  final int id;
  final String title;
  final String description;

  TradeReportLearningCard({
    required this.id,
    required this.title,
    required this.description,
  });

  factory TradeReportLearningCard.fromJson(Map<String, dynamic> json) {
    return TradeReportLearningCard(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

class TradeReport {
  final bool success;
  final int tradeCycleId;
  final String overallEvaluation;
  final String marketContext;
  final TradeReportIndicator buyRsi;
  final TradeReportIndicator buyMacd;
  final String buyEvaluation;
  final String buyImprovement;
  final TradeReportIndicator sellRsi;
  final TradeReportIndicator sellMacd;
  final String sellEvaluation;
  final String sellImprovement;
  final String generatedAt;
  final int tokensUsed;
  final String interval;
  final List<TradeReportLearningCard> learningCards;

  TradeReport({
    required this.success,
    required this.tradeCycleId,
    required this.overallEvaluation,
    required this.marketContext,
    required this.buyRsi,
    required this.buyMacd,
    required this.buyEvaluation,
    required this.buyImprovement,
    required this.sellRsi,
    required this.sellMacd,
    required this.sellEvaluation,
    required this.sellImprovement,
    required this.generatedAt,
    required this.tokensUsed,
    required this.interval,
    required this.learningCards,
  });

  factory TradeReport.fromJson(Map<String, dynamic> json) {
    return TradeReport(
      success: json['success'] as bool? ?? false,
      tradeCycleId: json['tradeCycleId'] as int,
      overallEvaluation: json['overallEvaluation'] as String,
      marketContext: json['marketContext'] as String,
      buyRsi: TradeReportIndicator.fromJson(json['buyAnalysis']['RSI'] as Map<String, dynamic>),
      buyMacd: TradeReportIndicator.fromJson(json['buyAnalysis']['MACD'] as Map<String, dynamic>),
      buyEvaluation: json['buyEvaluation'] as String,
      buyImprovement: json['buyImprovement'] as String,
      sellRsi: TradeReportIndicator.fromJson(json['sellAnalysis']['RSI'] as Map<String, dynamic>),
      sellMacd: TradeReportIndicator.fromJson(json['sellAnalysis']['MACD'] as Map<String, dynamic>),
      sellEvaluation: json['sellEvaluation'] as String,
      sellImprovement: json['sellImprovement'] as String,
      generatedAt: json['generatedAt'] as String,
      tokensUsed: json['tokensUsed'] as int? ?? 0,
      interval: json['interval'] as String? ?? '',
      learningCards: (json['learningCards'] as List? ?? [])
          .map((e) => TradeReportLearningCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}


