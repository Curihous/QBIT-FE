import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class OrderModel {
  final String symbol;
  final String quantity;
  @JsonKey(unknownEnumValue: OrderSide.unknown)
  final OrderSide side;
  @JsonKey(unknownEnumValue: OrderType.unknown)
  final OrderType type;
  @JsonKey(unknownEnumValue: TimeInForce.unknown)
  final TimeInForce timeInForce;
  final String? limitPrice;
  final String? stopPrice;
  
  // 추가 필드들 (API 응답용)
  final String? orderId;
  @JsonKey(unknownEnumValue: OrderStatus.unknown)
  final OrderStatus? status;
  final String? filledQuantity;
  final String? filledAvgPrice;
  final String? createdAt;
  final String? filledAt;

  OrderModel({
    required this.symbol,
    required this.quantity,
    required this.side,
    required this.type,
    required this.timeInForce,
    this.limitPrice,
    this.stopPrice,
    this.orderId,
    this.status,
    this.filledQuantity,
    this.filledAvgPrice,
    this.createdAt,
    this.filledAt,
  });

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);

  // 편의 메서드들
  double get quantityAsDouble => double.tryParse(quantity) ?? 0.0;
  double get limitPriceAsDouble => double.tryParse(limitPrice ?? '0') ?? 0.0;
  double get stopPriceAsDouble => double.tryParse(stopPrice ?? '0') ?? 0.0;
  
  // 사이드 표시명
  String get sideDisplayName => side == OrderSide.buy ? '매수' : '매도';
  
  // 타입 표시명
  String get typeDisplayName {
    switch (type) {
      case OrderType.market: return '시장가';
      case OrderType.limit: return '지정가';
      default: return type.name;
    }
  }
  
  // 유효기간 표시명
  String get timeInForceDisplayName {
    switch (timeInForce) {
      case TimeInForce.day: return '당일';
      case TimeInForce.gtc: return '지정일까지';
      case TimeInForce.ioc: return '즉시체결';
      case TimeInForce.fok: return '전량체결';
      default: return timeInForce.name;
    }
  }

  @override
  String toString() {
    return 'OrderModel(symbol: $symbol, quantity: $quantity, side: $side, type: $type, timeInForce: $timeInForce, limitPrice: $limitPrice, stopPrice: $stopPrice, orderId: $orderId, status: $status)';
  }
}

// Order Request Model
@JsonSerializable()
class OrderRequest {
  final String symbol;
  final String quantity;
  @JsonKey(unknownEnumValue: OrderSide.unknown)
  final OrderSide side;
  @JsonKey(unknownEnumValue: OrderType.unknown)
  final OrderType type;
  @JsonKey(unknownEnumValue: TimeInForce.unknown)
  final TimeInForce timeInForce;
  final String? limitPrice;
  final String? stopPrice;

  OrderRequest({
    required this.symbol,
    required this.quantity,
    required this.side,
    required this.type,
    required this.timeInForce,
    this.limitPrice,
    this.stopPrice,
  });

  Map<String, dynamic> toJson() => _$OrderRequestToJson(this);
  factory OrderRequest.fromJson(Map<String, dynamic> json) => _$OrderRequestFromJson(json);
}

// Order Response Model
@JsonSerializable(explicitToJson: true)
class OrderResponse {
  final OrderModel order;
  final String message;

  OrderResponse({
    required this.order,
    required this.message,
  });

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
  factory OrderResponse.fromJson(Map<String, dynamic> json) => _$OrderResponseFromJson(json);
}

// Enums
@JsonEnum()
enum OrderType {
  @JsonValue('limit')
  limit,
  @JsonValue('market')
  market,
  @JsonValue('stop')
  stop,
  @JsonValue('stop_limit')
  stopLimit,
  @JsonValue('trailing_stop')
  trailingStop,
  unknown,
}

@JsonEnum()
enum OrderSide {
  @JsonValue('buy')
  buy,
  @JsonValue('sell')
  sell,
  unknown,
}

@JsonEnum()
enum OrderStatus {
  @JsonValue('new')
  newOrder,
  @JsonValue('pending_new')
  pendingNew,
  @JsonValue('accepted')
  accepted,
  @JsonValue('pending_cancel')
  pendingCancel,
  @JsonValue('pending_replace')
  pendingReplace,
  @JsonValue('partially_filled')
  partiallyFilled,
  @JsonValue('filled')
  filled,
  @JsonValue('canceled')
  canceled,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expired')
  expired,
  @JsonValue('done_for_day')
  doneForDay,
  @JsonValue('suspended')
  suspended,
  unknown,
}

@JsonEnum()
enum TimeInForce {
  @JsonValue('day')
  day,
  @JsonValue('gtc')
  gtc,
  @JsonValue('ioc')
  ioc,
  @JsonValue('fok')
  fok,
  @JsonValue('gtx')
  gtx,
  @JsonValue('gtd')
  gtd,
  unknown,
}