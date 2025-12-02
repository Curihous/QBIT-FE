import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/api/api_client.dart';
import 'package:qbit_services/models/record_model.dart';

class RecordApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();

  /// 월별 거래 기록 조회
  static Future<RecordPageResponse?> getMonthlyRecords({
    required int year,
    required int month,
    String? side, // "BUY" or "SELL"
    int page = 0,
    int size = 10,
  }) async {
    try {
      logger.i('월별 거래 기록 조회 시작: $year-$month');

      final queryParams = <String, dynamic>{
        'year': year,
        'month': month,
        'page': page,
        'size': size,
      };

      if (side != null) {
        queryParams['side'] = side;
      }

      final response = await _dio.get(
        '/journals/monthly',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        logger.i('월별 거래 기록 조회 성공');
        return RecordPageResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        logger.e('월별 거래 기록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('월별 거래 기록 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 거래 기록 작성
  static Future<RecordModel?> createRecord({
    required int orderId,
    required String content,
    required TradeEmotion tradeEmotion,
  }) async {
    try {
      logger.i('거래 기록 작성 시작: orderId=$orderId');

      final request = CreateRecordRequest(
        content: content,
        tradeEmotion: tradeEmotion,
      );

      final response = await _dio.post(
        '/journals/orders/$orderId',
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('거래 기록 작성 성공');
        return RecordModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        logger.e('거래 기록 작성 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('거래 기록 작성 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('요청 데이터: ${error.requestOptions.data}');
      }
      return null;
    }
  }

  /// 거래 기록 수정
  static Future<RecordModel?> updateRecord({
    required int recordId,
    required String content,
    required TradeEmotion tradeEmotion,
  }) async {
    try {
      logger.i('거래 기록 수정 시작: recordId=$recordId');

      final request = UpdateRecordRequest(
        content: content,
        tradeEmotion: tradeEmotion,
      );

      final response = await _dio.put(
        '/journals/$recordId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        logger.i('거래 기록 수정 성공');
        return RecordModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        logger.e('거래 기록 수정 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('거래 기록 수정 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 거래 기록 삭제
  /// DELETE /journals/{journalId}
  static Future<bool> deleteRecord({
    required int recordId,
  }) async {
    try {
      logger.i('거래 기록 삭제 시작: recordId=$recordId');

      final response = await _dio.delete(
        '/journals/$recordId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('거래 기록 삭제 성공');
        return true;
      } else {
        logger.e('거래 기록 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      logger.e('거래 기록 삭제 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
      }
      return false;
    }
  }

  /// 월별 거래 통계 조회
  static Future<MonthlyTradeStatisticsResponse?> getMonthlyStatistics({
    required int year,
    required int month,
  }) async {
    try {
      logger.i('월별 거래 통계 조회 시작: $year-$month');

      final response = await _dio.get(
        '/trading/statistics/monthly',
        queryParameters: {
          'year': year,
          'month': month,
        },
      );

      if (response.statusCode == 200) {
        logger.i('월별 거래 통계 조회 성공');
        return MonthlyTradeStatisticsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        logger.e('월별 거래 통계 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('월별 거래 통계 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
      }
      return null;
    }
  }
}

