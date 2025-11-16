// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommend_column_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendColumnResponse _$RecommendColumnResponseFromJson(
  Map<String, dynamic> json,
) => RecommendColumnResponse(
  success: json['success'] as bool,
  source: $enumDecodeNullable(_$ColumnSourceEnumMap, json['source']),
  message: json['message'] as String?,
  column: Column.fromJson(json['column'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RecommendColumnResponseToJson(
  RecommendColumnResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'source': _$ColumnSourceEnumMap[instance.source],
  'message': instance.message,
  'column': instance.column,
};

const _$ColumnSourceEnumMap = {
  ColumnSource.portfolio: 'portfolio',
  ColumnSource.correlation: 'correlation',
  ColumnSource.popular: 'popular',
};
