// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_cycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeCycle _$TradeCycleFromJson(Map<String, dynamic> json) => TradeCycle(
  id: json['id'] as String,
  userId: json['userId'] as String,
  symbol: json['symbol'] as String,
  side: json['side'] as String,
  quantity: (json['quantity'] as num).toInt(),
  avgPrice: (json['avgPrice'] as num).toDouble(),
  executedAt: DateTime.parse(json['executedAt'] as String),
  orderId: json['orderId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TradeCycleToJson(TradeCycle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'symbol': instance.symbol,
      'side': instance.side,
      'quantity': instance.quantity,
      'avgPrice': instance.avgPrice,
      'executedAt': instance.executedAt.toIso8601String(),
      'orderId': instance.orderId,
      'metadata': instance.metadata,
    };
