import 'package:json_annotation/json_annotation.dart';

part 'trade_cycle.g.dart';

/// 거래 사이클 모델
@JsonSerializable()
class TradeCycle {
  final String id;
  final String userId;
  final String symbol;
  final String side;
  final int quantity;
  final double avgPrice;
  final DateTime executedAt;
  final String? orderId;
  final Map<String, dynamic>? metadata;

  const TradeCycle({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.avgPrice,
    required this.executedAt,
    this.orderId,
    this.metadata,
  });

  factory TradeCycle.fromJson(Map<String, dynamic> json) =>
      _$TradeCycleFromJson(json);

  Map<String, dynamic> toJson() => _$TradeCycleToJson(this);

  @override
  String toString() {
    return 'TradeCycle(id: $id, userId: $userId, symbol: $symbol, '
        'side: $side, quantity: $quantity, avgPrice: $avgPrice, '
        'executedAt: $executedAt)';
  }
}
