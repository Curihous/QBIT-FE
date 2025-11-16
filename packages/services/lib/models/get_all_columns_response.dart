import 'package:json_annotation/json_annotation.dart';
import 'column.dart';

part 'get_all_columns_response.g.dart';

@JsonSerializable()
class GetAllColumnsResponse {
  final bool success;
  @JsonKey(name: 'total_count')
  final int totalCount;
  final List<Column> columns;

  GetAllColumnsResponse({
    required this.success,
    required this.totalCount,
    required this.columns,
  });

  factory GetAllColumnsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetAllColumnsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GetAllColumnsResponseToJson(this);
}

