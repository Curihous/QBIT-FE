import 'package:json_annotation/json_annotation.dart';
import 'column.dart';

part 'recommend_column_response.g.dart';

enum ColumnSource {
  @JsonValue('portfolio')
  portfolio,
  @JsonValue('correlation')
  correlation,
  @JsonValue('popular')
  popular,
}

@JsonSerializable()
class RecommendColumnResponse {
  final bool success;
  final ColumnSource? source;
  final String? message;
  final Column column;

  RecommendColumnResponse({
    required this.success,
    this.source,
    this.message,
    required this.column,
  });

  factory RecommendColumnResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendColumnResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendColumnResponseToJson(this);
}

