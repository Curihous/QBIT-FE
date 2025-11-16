// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_all_columns_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAllColumnsResponse _$GetAllColumnsResponseFromJson(
  Map<String, dynamic> json,
) => GetAllColumnsResponse(
  success: json['success'] as bool,
  totalCount: (json['total_count'] as num).toInt(),
  columns: (json['columns'] as List<dynamic>)
      .map((e) => Column.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAllColumnsResponseToJson(
  GetAllColumnsResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'total_count': instance.totalCount,
  'columns': instance.columns,
};
