import 'package:json_annotation/json_annotation.dart';
import 'column.dart';

part 'get_column_response.g.dart';

@JsonSerializable()
class GetColumnResponse {
  final bool success;
  final Column column;

  GetColumnResponse({
    required this.success,
    required this.column,
  });

  factory GetColumnResponse.fromJson(Map<String, dynamic> json) =>
      _$GetColumnResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetColumnResponseToJson(this);
}

