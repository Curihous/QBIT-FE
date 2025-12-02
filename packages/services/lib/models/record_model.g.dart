// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordModel _$RecordModelFromJson(Map<String, dynamic> json) => RecordModel(
  recordId: (json['journalId'] as num).toInt(),
  orderId: (json['orderRequestId'] as num).toInt(),
  symbol: json['symbol'] as String,
  side: json['orderSide'] as String,
  content: json['content'] as String,
  tradeEmotion: $enumDecode(_$TradeEmotionEnumMap, json['tradeEmotion']),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
  totalAmount: RecordModel._doubleToStringNullable(json['executedAmount']),
  status: json['orderStatus'] as String?,
);

Map<String, dynamic> _$RecordModelToJson(RecordModel instance) =>
    <String, dynamic>{
      'journalId': instance.recordId,
      'orderRequestId': instance.orderId,
      'symbol': instance.symbol,
      'orderSide': instance.side,
      'content': instance.content,
      'tradeEmotion': _$TradeEmotionEnumMap[instance.tradeEmotion]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'executedAmount': instance.totalAmount,
      'orderStatus': instance.status,
    };

const _$TradeEmotionEnumMap = {
  TradeEmotion.laugh: 'LAUGH',
  TradeEmotion.love: 'LOVE',
  TradeEmotion.cool: 'COOL',
  TradeEmotion.excellent: 'EXCELLENT',
  TradeEmotion.sobbing: 'SOBBING',
  TradeEmotion.slump: 'SLUMP',
  TradeEmotion.anger: 'ANGER',
  TradeEmotion.neutral: 'NEUTRAL',
  TradeEmotion.awkward: 'AWKWARD',
};

RecordPageResponse _$RecordPageResponseFromJson(Map<String, dynamic> json) =>
    RecordPageResponse(
      currentPage: (json['currentPage'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      content: (json['content'] as List<dynamic>)
          .map((e) => RecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecordPageResponseToJson(RecordPageResponse instance) =>
    <String, dynamic>{
      'currentPage': instance.currentPage,
      'pageSize': instance.pageSize,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
      'content': instance.content,
    };

CreateRecordRequest _$CreateRecordRequestFromJson(Map<String, dynamic> json) =>
    CreateRecordRequest(
      content: json['content'] as String,
      tradeEmotion: $enumDecode(_$TradeEmotionEnumMap, json['tradeEmotion']),
    );

Map<String, dynamic> _$CreateRecordRequestToJson(
  CreateRecordRequest instance,
) => <String, dynamic>{
  'content': instance.content,
  'tradeEmotion': _$TradeEmotionEnumMap[instance.tradeEmotion]!,
};

UpdateRecordRequest _$UpdateRecordRequestFromJson(Map<String, dynamic> json) =>
    UpdateRecordRequest(
      content: json['content'] as String,
      tradeEmotion: $enumDecode(_$TradeEmotionEnumMap, json['tradeEmotion']),
    );

Map<String, dynamic> _$UpdateRecordRequestToJson(
  UpdateRecordRequest instance,
) => <String, dynamic>{
  'content': instance.content,
  'tradeEmotion': _$TradeEmotionEnumMap[instance.tradeEmotion]!,
};

MonthlyTradeStatisticsResponse _$MonthlyTradeStatisticsResponseFromJson(
  Map<String, dynamic> json,
) => MonthlyTradeStatisticsResponse(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  totalTradeCount: (json['totalTradeCount'] as num).toInt(),
  profitRate: (json['profitRate'] as num).toDouble(),
  cumulativeProfitLoss: (json['cumulativeProfitLoss'] as num).toDouble(),
);

Map<String, dynamic> _$MonthlyTradeStatisticsResponseToJson(
  MonthlyTradeStatisticsResponse instance,
) => <String, dynamic>{
  'year': instance.year,
  'month': instance.month,
  'totalTradeCount': instance.totalTradeCount,
  'profitRate': instance.profitRate,
  'cumulativeProfitLoss': instance.cumulativeProfitLoss,
};
