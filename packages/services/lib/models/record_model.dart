import 'package:json_annotation/json_annotation.dart';

part 'record_model.g.dart';

@JsonSerializable()
class RecordModel {
  @JsonKey(name: 'journalId')
  final int recordId;
  @JsonKey(name: 'orderRequestId')
  final int orderId;
  final String symbol;
  @JsonKey(name: 'orderSide')
  final String side; // "BUY" or "SELL"
  final String content;
  final TradeEmotion tradeEmotion;
  final String createdAt;
  final String? updatedAt;
  @JsonKey(name: 'executedAmount', fromJson: _doubleToStringNullable)
  final String? totalAmount;
  @JsonKey(name: 'orderStatus')
  final String? status; // "PENDING", "FILLED", etc.
  
  static String? _doubleToStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }

  RecordModel({
    required this.recordId,
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.content,
    required this.tradeEmotion,
    required this.createdAt,
    this.updatedAt,
    this.totalAmount,
    this.status,
  });

  factory RecordModel.fromJson(Map<String, dynamic> json) =>
      _$RecordModelFromJson(json);
  Map<String, dynamic> toJson() => _$RecordModelToJson(this);
}

@JsonSerializable()
class RecordPageResponse {
  @JsonKey(name: 'currentPage')
  final int currentPage;
  @JsonKey(name: 'pageSize')
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final List<RecordModel> content;

  RecordPageResponse({
    required this.currentPage,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.content,
  });

  factory RecordPageResponse.fromJson(Map<String, dynamic> json) =>
      _$RecordPageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecordPageResponseToJson(this);
}

@JsonSerializable()
class CreateRecordRequest {
  final String content;
  final TradeEmotion tradeEmotion;

  CreateRecordRequest({
    required this.content,
    required this.tradeEmotion,
  });

  Map<String, dynamic> toJson() => _$CreateRecordRequestToJson(this);
}

@JsonSerializable()
class UpdateRecordRequest {
  final String content;
  final TradeEmotion tradeEmotion;

  UpdateRecordRequest({
    required this.content,
    required this.tradeEmotion,
  });

  Map<String, dynamic> toJson() => _$UpdateRecordRequestToJson(this);
}

@JsonSerializable()
class MonthlyTradeStatisticsResponse {
  final int year;
  final int month;
  @JsonKey(name: 'totalTradeCount')
  final int totalTradeCount;
  @JsonKey(name: 'profitRate')
  final double profitRate;
  @JsonKey(name: 'cumulativeProfitLoss')
  final double cumulativeProfitLoss;

  MonthlyTradeStatisticsResponse({
    required this.year,
    required this.month,
    required this.totalTradeCount,
    required this.profitRate,
    required this.cumulativeProfitLoss,
  });

  factory MonthlyTradeStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTradeStatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyTradeStatisticsResponseToJson(this);
}

@JsonEnum()
enum TradeEmotion {
  @JsonValue('LAUGH')
  laugh,
  @JsonValue('LOVE')
  love,
  @JsonValue('COOL')
  cool,
  @JsonValue('EXCELLENT')
  excellent,
  @JsonValue('SOBBING')
  sobbing,
  @JsonValue('SLUMP')
  slump,
  @JsonValue('ANGER')
  anger,
  @JsonValue('NEUTRAL')
  neutral,
  @JsonValue('AWKWARD')
  awkward,
}

extension TradeEmotionExtension on TradeEmotion {
  String get assetPath {
    switch (this) {
      case TradeEmotion.laugh:
        return 'assets/icons/record/trade_emotion/trade_emotion_laugh.svg';
      case TradeEmotion.love:
        return 'assets/icons/record/trade_emotion/trade_emotion_love.svg';
      case TradeEmotion.cool:
        return 'assets/icons/record/trade_emotion/trade_emotion_cool.svg';
      case TradeEmotion.excellent:
        return 'assets/icons/record/trade_emotion/trade_emotion_excellent.svg';
      case TradeEmotion.sobbing:
        return 'assets/icons/record/trade_emotion/trade_emotion_sobbing.svg';
      case TradeEmotion.slump:
        return 'assets/icons/record/trade_emotion/trade_emotion_slump.svg';
      case TradeEmotion.anger:
        return 'assets/icons/record/trade_emotion/trade_emotion_anger.svg';
      case TradeEmotion.neutral:
        return 'assets/icons/record/trade_emotion/trade_emotion_neutral.svg';
      case TradeEmotion.awkward:
        return 'assets/icons/record/trade_emotion/trade_emotion_awkward.svg';
    }
  }
}

