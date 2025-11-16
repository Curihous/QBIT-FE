import 'package:json_annotation/json_annotation.dart';
import 'column_section.dart';

part 'column.g.dart';

@JsonSerializable()
class Column {
  final String ticker;
  final String title;
  final String? subtitle;
  final List<ColumnSection> sections;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'source_title')
  final String? sourceTitle;
  @JsonKey(name: 'source_publisher')
  final String? sourcePublisher;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  @JsonKey(name: 'source_published_at')
  final String? sourcePublishedAt;
  @JsonKey(name: 'source_ticker')
  final String? sourceTicker;
  @JsonKey(name: 'generated_at')
  final String? generatedAt;

  Column({
    required this.ticker,
    required this.title,
    this.subtitle,
    required this.sections,
    this.imageUrl,
    this.sourceTitle,
    this.sourcePublisher,
    this.sourceUrl,
    this.sourcePublishedAt,
    this.sourceTicker,
    this.generatedAt,
  });

  factory Column.fromJson(Map<String, dynamic> json) =>
      _$ColumnFromJson(json);
  Map<String, dynamic> toJson() => _$ColumnToJson(this);
}

