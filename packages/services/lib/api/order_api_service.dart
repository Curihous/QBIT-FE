import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/api/api_client.dart';
import 'package:qbit_services/models/order_model.dart';

class OrderApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();

  /// 주문 생성
  static Future<Map<String, dynamic>?> createOrder(OrderModel order) async {
    try {
      logger.i('주문 생성 시작: ${order.symbol} ${order.side} ${order.quantity}주');
      logger.i('주문 데이터: ${order.toJson()}');
      
      // 토큰 상태 확인
      await ApiClient.debugTokenStatus();
      
      final response = await _dio.post('/trading/orders', data: order.toJson());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('주문 생성 성공');
        logger.i('응답 데이터: ${response.data}');
        return response.data;
      } else {
        logger.e('주문 생성 실패: ${response.statusCode}');
        logger.e('응답 데이터: ${response.data}');
        return null;
      }
    } catch (error) {
      logger.e('주문 생성 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
        
        if (error.response?.statusCode == 400) {
          logger.e('400 에러: 잘못된 요청 - 주문 파라미터 확인 필요');
        } else if (error.response?.statusCode == 401) {
          logger.e('401 에러: 인증되지 않은 요청');
        } else if (error.response?.statusCode == 403) {
          logger.e('403 에러: 권한 없음 - Alpaca 계정 연결 확인 필요');
        }
      }
      return null;
    }
  }

  /// 주문 내역 조회
  static Future<List<Map<String, dynamic>>?> getOrders({
    String? symbol,
    String? status,
    int limit = 100,
  }) async {
    try {
      logger.i('주문 내역 조회 시작');
      
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (symbol != null) {
        queryParams['symbol'] = symbol;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final response = await _dio.get('/trading/orders', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        logger.i('주문 내역 조회 성공');
        logger.i('응답 데이터: ${response.data}');
        
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          logger.e('응답 데이터가 List가 아닙니다: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('주문 내역 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('주문 내역 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 특정 주문 조회
  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      logger.i('주문 조회 시작: $orderId');
      
      final response = await _dio.get('/trading/orders/$orderId');
      
      if (response.statusCode == 200) {
        logger.i('주문 조회 성공');
        logger.i('응답 데이터: ${response.data}');
        return response.data;
      } else {
        logger.e('주문 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('주문 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 주문 취소
  static Future<bool> cancelOrder(String orderId) async {
    try {
      logger.i('주문 취소 시작: $orderId');
      
      final response = await _dio.delete('/trading/orders/$orderId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('주문 취소 성공');
        return true;
      } else {
        logger.e('주문 취소 실패: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      logger.e('주문 취소 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return false;
    }
  }
}