import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_core/config/app_config.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';
import 'package:qbit_core/models/user.dart';

final logger = Logger();

/// 기본 API 서비스 클래스
class BaseApiService {
  late final Dio _dio;

  BaseApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          logger.d('API 요청: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('API 응답: ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) async {
          logger.e('API 에러: ${error.message}');
          
          if (error is DioException) {
            switch (error.type) {
              case DioExceptionType.connectionTimeout:
              case DioExceptionType.sendTimeout:
              case DioExceptionType.receiveTimeout:
                throw NetworkException(
                  message: '네트워크 연결 시간 초과',
                  originalError: error.message,
                );
              case DioExceptionType.badResponse:
                throw ApiException(
                  message: '서버 오류: ${error.response?.statusCode}',
                  statusCode: error.response?.statusCode,
                  endpoint: error.requestOptions.uri.toString(),
                );
              case DioExceptionType.cancel:
                throw ApiException(
                  message: '요청이 취소되었습니다',
                  endpoint: error.requestOptions.uri.toString(),
                );
              case DioExceptionType.connectionError:
                throw NetworkException(
                  message: '네트워크 연결 오류',
                  originalError: error.message,
                );
              default:
                throw ApiException(
                  message: '알 수 없는 오류: ${error.message}',
                  endpoint: error.requestOptions.uri.toString(),
                );
            }
          }
          
          handler.next(error);
        },
      ),
    );
  }

  /// GET 요청
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'GET 요청 실패: $e',
        endpoint: path,
      );
    }
  }

  /// POST 요청
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'POST 요청 실패: $e',
        endpoint: path,
      );
    }
  }

  /// PUT 요청
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'PUT 요청 실패: $e',
        endpoint: path,
      );
    }
  }

  /// DELETE 요청
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw ApiException(
        message: 'DELETE 요청 실패: $e',
        endpoint: path,
      );
    }
  }
}
