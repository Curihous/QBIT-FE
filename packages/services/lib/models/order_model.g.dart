// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  symbol: json['symbol'] as String,
  quantity: json['quantity'] as String,
  side: $enumDecode(
    _$OrderSideEnumMap,
    json['side'],
    unknownValue: OrderSide.unknown,
  ),
  type: $enumDecode(
    _$OrderTypeEnumMap,
    json['type'],
    unknownValue: OrderType.unknown,
  ),
  timeInForce: $enumDecode(
    _$TimeInForceEnumMap,
    json['timeInForce'],
    unknownValue: TimeInForce.unknown,
  ),
  limitPrice: json['limitPrice'] as String?,
  stopPrice: json['stopPrice'] as String?,
  orderId: json['orderId'] as String?,
  status: $enumDecodeNullable(
    _$OrderStatusEnumMap,
    json['status'],
    unknownValue: OrderStatus.unknown,
  ),
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
  OrderSide.unknown: 'unknown',
};

const _$OrderTypeEnumMap = {
  OrderType.limit: 'limit',
  OrderType.market: 'market',
  OrderType.stop: 'stop',
  OrderType.stopLimit: 'stop_limit',
  OrderType.trailingStop: 'trailing_stop',
  OrderType.unknown: 'unknown',
};

const _$TimeInForceEnumMap = {
  TimeInForce.day: 'day',
  TimeInForce.gtc: 'gtc',
  TimeInForce.opg: 'opg',
  TimeInForce.cls: 'cls',
  TimeInForce.ioc: 'ioc',
  TimeInForce.fok: 'fok',
  TimeInForce.unknown: 'unknown',
};

const _$OrderStatusEnumMap = {
  OrderStatus.newOrder: 'new',
  OrderStatus.pendingNew: 'pending_new',
  OrderStatus.accepted: 'accepted',
  OrderStatus.pendingCancel: 'pending_cancel',
  OrderStatus.pendingReplace: 'pending_replace',
  OrderStatus.partiallyFilled: 'partially_filled',
  OrderStatus.filled: 'filled',
  OrderStatus.doneForDay: 'done_for_day',
  OrderStatus.canceled: 'canceled',
  OrderStatus.expired: 'expired',
  OrderStatus.replaced: 'replaced',
  OrderStatus.pendingReview: 'pending_review',
  OrderStatus.unknown: 'unknown',
};

OrderRequest _$OrderRequestFromJson(Map<String, dynamic> json) => OrderRequest(
  symbol: json['symbol'] as String,
  quantity: json['quantity'] as String,
  side: $enumDecode(
    _$OrderSideEnumMap,
    json['side'],
    unknownValue: OrderSide.unknown,
  ),
  type: $enumDecode(
    _$OrderTypeEnumMap,
    json['type'],
    unknownValue: OrderType.unknown,
  ),
  timeInForce: $enumDecode(
    _$TimeInForceEnumMap,
    json['timeInForce'],
    unknownValue: TimeInForce.unknown,
  ),
  limitPrice: json['limitPrice'] as String?,
  stopPrice: json['stopPrice'] as String?,
);

Map<String, dynamic> _$OrderRequestToJson(OrderRequest instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'quantity': instance.quantity,
      'side': _$OrderSideEnumMap[instance.side]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
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
