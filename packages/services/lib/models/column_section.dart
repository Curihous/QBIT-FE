import 'package:json_annotation/json_annotation.dart';

part 'column_section.g.dart';

@JsonSerializable()
class ColumnSection {
  @JsonKey(name: 'header')
  final String? header;
  @JsonKey(name: 'body')
  final String? body;
  @JsonKey(name: 'list')
  final List<String>? list;

  ColumnSection({
    this.header,
    this.body,
    this.list,
  });

  factory ColumnSection.fromJson(Map<String, dynamic> json) =>
      _$ColumnSectionFromJson(json);
  Map<String, dynamic> toJson() => _$ColumnSectionToJson(this);
}

