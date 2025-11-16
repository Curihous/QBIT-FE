// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Column _$ColumnFromJson(Map<String, dynamic> json) => Column(
  ticker: json['ticker'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String?,
  sections: (json['sections'] as List<dynamic>)
      .map((e) => ColumnSection.fromJson(e as Map<String, dynamic>))
      .toList(),
  imageUrl: json['image_url'] as String?,
  sourceTitle: json['source_title'] as String?,
  sourcePublisher: json['source_publisher'] as String?,
  sourceUrl: json['source_url'] as String?,
  sourcePublishedAt: json['source_published_at'] as String?,
  sourceTicker: json['source_ticker'] as String?,
  generatedAt: json['generated_at'] as String?,
);

Map<String, dynamic> _$ColumnToJson(Column instance) => <String, dynamic>{
  'ticker': instance.ticker,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'sections': instance.sections,
  'image_url': instance.imageUrl,
  'source_title': instance.sourceTitle,
  'source_publisher': instance.sourcePublisher,
  'source_url': instance.sourceUrl,
  'source_published_at': instance.sourcePublishedAt,
  'source_ticker': instance.sourceTicker,
  'generated_at': instance.generatedAt,
};
