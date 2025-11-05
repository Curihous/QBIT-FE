// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_update_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderUpdateMessage _$OrderUpdateMessageFromJson(Map<String, dynamic> json) =>
    OrderUpdateMessage(
      type: json['type'] as String,
      orderId: json['orderId'] as String?,
      alpacaOrderId: json['alpacaOrderId'] as String?,
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      status: json['status'] as String,
      filledQuantity: (json['filledQuantity'] as num?)?.toInt(),
      filledAvgPrice: (json['filledAvgPrice'] as num?)?.toDouble(),
      filledAt: json['filledAt'] == null
          ? null
          : DateTime.parse(json['filledAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OrderUpdateMessageToJson(OrderUpdateMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'orderId': instance.orderId,
      'alpacaOrderId': instance.alpacaOrderId,
      'symbol': instance.symbol,
      'side': instance.side,
      'status': instance.status,
      'filledQuantity': instance.filledQuantity,
      'filledAvgPrice': instance.filledAvgPrice,
      'filledAt': instance.filledAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'metadata': instance.metadata,
    };
