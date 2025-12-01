// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordModel _$RecordModelFromJson(Map<String, dynamic> json) => RecordModel(
  recordId: (json['journalId'] as num).toInt(),
  orderId: (json['orderId'] as num).toInt(),
  symbol: json['symbol'] as String,
  side: json['side'] as String,
  content: json['content'] as String,
  tradeEmotion: $enumDecode(_$TradeEmotionEnumMap, json['tradeEmotion']),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String?,
  totalAmount: json['totalAmount'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$RecordModelToJson(RecordModel instance) =>
    <String, dynamic>{
      'journalId': instance.recordId,
      'orderId': instance.orderId,
      'symbol': instance.symbol,
      'side': instance.side,
      'content': instance.content,
      'tradeEmotion': _$TradeEmotionEnumMap[instance.tradeEmotion]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'totalAmount': instance.totalAmount,
      'status': instance.status,
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
