// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      orderId: json['orderId'] as int,
      alpacaOrderId: json['alpacaOrderId'] as String,
      symbol: json['symbol'] as String,
      side: $enumDecode(_$OrderSideEnumMap, json['side']),
      quantity: json['qty'] as String,
      filledQuantity: json['filledQty'] as String,
      filledAvgPrice: json['filledAvgPrice'] as String,
      type: $enumDecode(_$OrderTypeEnumMap, json['type']),
      timeInForce: $enumDecode(_$TimeInForceEnumMap, json['timeInForce']),
      limitPrice: json['limitPrice'] as String?,
      stopPrice: json['stopPrice'] as String?,
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
      filledAt: json['filledAt'] == null
          ? null
          : DateTime.parse(json['filledAt'] as String),
      canceledAt: json['canceledAt'] == null
          ? null
          : DateTime.parse(json['canceledAt'] as String),
      replacedAt: json['replacedAt'] == null
          ? null
          : DateTime.parse(json['replacedAt'] as String),
      replacedBy: json['replacedBy'] as String?,
      replaces: json['replaces'] as String?,
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'alpacaOrderId': instance.alpacaOrderId,
      'symbol': instance.symbol,
      'side': _$OrderSideEnumMap[instance.side]!,
      'qty': instance.quantity,
      'filledQty': instance.filledQuantity,
      'filledAvgPrice': instance.filledAvgPrice,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'timeInForce': _$TimeInForceEnumMap[instance.timeInForce]!,
      'limitPrice': instance.limitPrice,
      'stopPrice': instance.stopPrice,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'filledAt': instance.filledAt?.toIso8601String(),
      'canceledAt': instance.canceledAt?.toIso8601String(),
      'replacedAt': instance.replacedAt?.toIso8601String(),
      'replacedBy': instance.replacedBy,
      'replaces': instance.replaces,
    };

OrderRequest _$OrderRequestFromJson(Map<String, dynamic> json) => OrderRequest(
      symbol: json['symbol'] as String?,
      quantity: json['quantity'] as String?,
      side: $enumDecodeNullable(_$OrderSideEnumMap, json['side']),
      type: $enumDecodeNullable(_$OrderTypeEnumMap, json['type']),
      timeInForce: $enumDecodeNullable(_$TimeInForceEnumMap, json['timeInForce']),
      limitPrice: json['limitPrice'] as String?,
      stopPrice: json['stopPrice'] as String?,
    );

Map<String, dynamic> _$OrderRequestToJson(OrderRequest instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'quantity': instance.quantity,
      'side': _$OrderSideEnumMap[instance.side],
      'type': _$OrderTypeEnumMap[instance.type],
      'timeInForce': _$TimeInForceEnumMap[instance.timeInForce],
      'limitPrice': instance.limitPrice,
      'stopPrice': instance.stopPrice,
    };

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      order: OrderModel.fromJson(json['order'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'order': instance.order,
      'message': instance.message,
    };

const _$OrderTypeEnumMap = {
  OrderType.limit: 'limit',
  OrderType.market: 'market',
};

const _$OrderSideEnumMap = {
  OrderSide.buy: 'buy',
  OrderSide.sell: 'sell',
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.filled: 'filled',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.rejected: 'rejected',
};

const _$TimeInForceEnumMap = {
  TimeInForce.day: 'day',
  TimeInForce.gtc: 'gtc',
  TimeInForce.ioc: 'ioc',
  TimeInForce.fok: 'fok',
};

T $enumDecode<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  if (enumValues.containsKey(source)) {
    return enumValues[source] as T;
  }

  if (unknownValue == null) {
    throw ArgumentError(
      '`$source` is not one of the supported values: '
      '${enumValues.values.join(', ')}',
    );
  }
  return unknownValue;
}

T? $enumDecodeNullable<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return $enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}
