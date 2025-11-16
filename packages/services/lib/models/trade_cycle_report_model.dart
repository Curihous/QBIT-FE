import 'package:qbit_services/models/candle_model.dart';

class TradePoint {
  final int timestamp; // Unix ms
  final String side; // BUY or SELL
  final double price;
  final double quantity;

  TradePoint({
    required this.timestamp,
    required this.side,
    required this.price,
    required this.quantity,
  });

  factory TradePoint.fromJson(Map<String, dynamic> json) {
    return TradePoint(
      timestamp: json['timestamp'] as int,
      side: json['side'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

/// /trade-cycles/{tradeCycleId} 응답 모델
class ReportTradeCycleResponse {
  final int tradeCycleId;
  final String symbol;
  final DateTime startDate;
  final DateTime? endDate;
  final String interval;
  final double profitLossRate;
  final double averageBuyPrice;
  final double? averageSellPrice;
  final double totalInvestmentAmount;
  final List<CandleData> chartData;
  final List<TradePoint> tradePoints;

  ReportTradeCycleResponse({
    required this.tradeCycleId,
    required this.symbol,
    required this.startDate,
    required this.endDate,
    required this.interval,
    required this.profitLossRate,
    required this.averageBuyPrice,
    required this.averageSellPrice,
    required this.totalInvestmentAmount,
    required this.chartData,
    required this.tradePoints,
  });

  factory ReportTradeCycleResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> chartList = json['chartData'] as List<dynamic>? ?? [];
    final List<dynamic> tradeList = json['tradePoints'] as List<dynamic>? ?? [];

    return ReportTradeCycleResponse(
      tradeCycleId: json['tradeCycleId'] as int,
      symbol: json['symbol'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      interval: json['interval'] as String,
      profitLossRate: (json['profitLossRate'] as num).toDouble(),
      averageBuyPrice: (json['averageBuyPrice'] as num).toDouble(),
      averageSellPrice: json['averageSellPrice'] != null
          ? (json['averageSellPrice'] as num).toDouble()
          : null,
      totalInvestmentAmount:
          (json['totalInvestmentAmount'] as num).toDouble(),
      chartData: chartList.map((e) {
        final m = e as Map<String, dynamic>;
        return CandleData(
          // API는 ms, 차트는 s 기준이므로 1000으로 나눔
          timestamp: (m['timestamp'] as int) ~/ 1000,
          open: double.parse(m['open'] as String),
          high: double.parse(m['high'] as String),
          low: double.parse(m['low'] as String),
          close: double.parse(m['close'] as String),
          volume: double.parse(m['volume'] as String),
        );
      }).toList(),
      tradePoints: tradeList
          .map((e) => TradePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}


