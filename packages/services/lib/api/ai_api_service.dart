import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/recommend_column_response.dart';
import '../models/get_column_response.dart';
import '../models/get_all_columns_response.dart';
import '../models/column.dart';
import '../models/api_error_response.dart';

final logger = Logger();

class AiApiService {
  static const String baseUrl = 'https://ai.qbit.o-r.kr';
  static const Duration timeout = Duration(seconds: 30);
  
  static late Dio _dio;
  static bool _initialized = false;

  static void _initialize() {
    if (_initialized) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _initialized = true;
  }

  /// 칼럼 추천 (포트폴리오 기반)
  static Future<RecommendColumnResponse> recommendColumn(
    List<String> tickers,
  ) async {
    _initialize();
    
    try {
      final response = await _dio.post(
        '/news/columns/recommend',
        data: {'tickers': tickers},
      );

      return RecommendColumnResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final error = ApiErrorResponse.fromJson(e.response?.data ?? {});
        throw ApiException(
          message: error.detail,
          statusCode: 404,
        );
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: '칼럼 추천에 실패했습니다: ${e.toString()}');
    }
  }

  /// 단일 칼럼 조회
  static Future<Column?> getColumnByTicker(String ticker) async {
    _initialize();
    
    try {
      final response = await _dio.get(
        '/news/columns/${ticker.toUpperCase()}',
      );

      final data = GetColumnResponse.fromJson(response.data);
      return data.column;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // 칼럼이 없음
      }
      throw _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: '칼럼 조회에 실패했습니다: ${e.toString()}');
    }
  }

  /// 전체 칼럼 목록 조회
  static Future<GetAllColumnsResponse> getAllColumns({
    int limit = 50,
  }) async {
    _initialize();
    
    try {
      final response = await _dio.get(
        '/news/columns',
        queryParameters: {'limit': limit},
      );

      return GetAllColumnsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: '칼럼 목록 조회에 실패했습니다: ${e.toString()}');
    }
  }

  static ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: '요청 시간이 초과되었습니다.',
        statusCode: e.response?.statusCode,
      );
    }

    if (e.response != null) {
      try {
        final error = ApiErrorResponse.fromJson(e.response?.data ?? {});
        return ApiException(
          message: error.detail,
          statusCode: e.response?.statusCode,
        );
      } catch (_) {
        return ApiException(
          message: '서버 오류가 발생했습니다.',
          statusCode: e.response?.statusCode ?? 500,
        );
      }
    }

    return ApiException(
      message: '네트워크 오류가 발생했습니다.',
      statusCode: null,
    );
  }
}

/// API 예외 클래스
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

