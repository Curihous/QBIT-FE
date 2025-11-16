// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'column_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ColumnSection _$ColumnSectionFromJson(Map<String, dynamic> json) =>
    ColumnSection(
      header: json['header'] as String?,
      body: json['body'] as String?,
      list: (json['list'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ColumnSectionToJson(ColumnSection instance) =>
    <String, dynamic>{
      'header': instance.header,
      'body': instance.body,
      'list': instance.list,
    };
