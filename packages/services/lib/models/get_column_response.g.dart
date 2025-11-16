// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_column_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetColumnResponse _$GetColumnResponseFromJson(Map<String, dynamic> json) =>
    GetColumnResponse(
      success: json['success'] as bool,
      column: Column.fromJson(json['column'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetColumnResponseToJson(GetColumnResponse instance) =>
    <String, dynamic>{'success': instance.success, 'column': instance.column};
