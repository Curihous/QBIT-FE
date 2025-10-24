import 'package:json_annotation/json_annotation.dart';

part 'order_update_message.g.dart';

/// 주문 상태 업데이트 메시지 모델
@JsonSerializable()
class OrderUpdateMessage {
  final String type;
  final String orderId;
  final String symbol;
  final String side;
  final String status;
  final int? filledQuantity;
  final double? filledAvgPrice;
  final DateTime? filledAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const OrderUpdateMessage({
    required this.type,
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.status,
    this.filledQuantity,
    this.filledAvgPrice,
    this.filledAt,
    this.errorMessage,
    this.metadata,
  });

  factory OrderUpdateMessage.fromJson(Map<String, dynamic> json) =>
      _$OrderUpdateMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OrderUpdateMessageToJson(this);

  @override
  String toString() {
    return 'OrderUpdateMessage(type: $type, orderId: $orderId, symbol: $symbol, '
        'side: $side, status: $status, filledQuantity: $filledQuantity, '
        'filledAvgPrice: $filledAvgPrice, filledAt: $filledAt)';
  }
}
