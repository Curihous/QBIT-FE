// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as String,
      side: $enumDecode(_$OrderSideEnumMap, json['side']),
      type: $enumDecode(_$OrderTypeEnumMap, json['type']),
      timeInForce: $enumDecode(_$TimeInForceEnumMap, json['timeInForce']),
      limitPrice: json['limitPrice'] as String?,
      stopPrice: json['stopPrice'] as String?,
      orderId: json['orderId'] as String?,
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']),
      filledQuantity: json['filledQuantity'] as String?,
      filledAvgPrice: json['filledAvgPrice'] as String?,
      createdAt: json['createdAt'] as String?,
      filledAt: json['filledAt'] as String?,
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'quantity': instance.quantity,
      'side': _$OrderSideEnumMap[instance.side]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'timeInForce': _$TimeInForceEnumMap[instance.timeInForce]!,
      'limitPrice': instance.limitPrice,
      'stopPrice': instance.stopPrice,
      'orderId': instance.orderId,
      'status': _$OrderStatusEnumMap[instance.status],
      'filledQuantity': instance.filledQuantity,
      'filledAvgPrice': instance.filledAvgPrice,
      'createdAt': instance.createdAt,
      'filledAt': instance.filledAt,
    };

const _$OrderSideEnumMap = {
  OrderSide.buy: 'buy',
  OrderSide.sell: 'sell',
};

const _$OrderTypeEnumMap = {
  OrderType.limit: 'limit',
  OrderType.market: 'market',
};

const _$TimeInForceEnumMap = {
  TimeInForce.day: 'day',
  TimeInForce.gtc: 'gtc',
  TimeInForce.ioc: 'ioc',
  TimeInForce.fok: 'fok',
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.filled: 'filled',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.rejected: 'rejected',
};

OrderRequest _$OrderRequestFromJson(Map<String, dynamic> json) => OrderRequest(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as String,
      side: $enumDecode(_$OrderSideEnumMap, json['side']),
      type: $enumDecode(_$OrderTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']),
      timeInForce: $enumDecode(_$TimeInForceEnumMap, json['timeInForce']),
      limitPrice: json['limitPrice'] as String?,
      stopPrice: json['stopPrice'] as String?,
    );

Map<String, dynamic> _$OrderRequestToJson(OrderRequest instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'quantity': instance.quantity,
      'side': _$OrderSideEnumMap[instance.side]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'status': _$OrderStatusEnumMap[instance.status],
      'timeInForce': _$TimeInForceEnumMap[instance.timeInForce]!,
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
      'order': instance.order.toJson(),
      'message': instance.message,
    };
