import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/api/api_client.dart';
import 'package:qbit_services/models/portfolio_overview_model.dart';
import 'package:qbit_services/models/portfolio_position_model.dart';

class PortfolioApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();

  /// 포트폴리오 오버뷰 조회 (90초 캐시)
  /// [period] - 조회 기간: '1D' (1일), '1W' (1주), '1M' (1개월), '1A' (1년) (기본값: '1M')
  /// 
  /// 백엔드 데이터 간격:
  /// - 1D (1일): 15Min 간격
  /// - 1W (1주): 1H 간격
  /// - 1M (1개월): 1D 간격
  /// - 1A (1년): 1D 간격
  /// 
  /// TODO: 백엔드에서 period 파라미터에 따라 실제 조회 기간이 반영되도록 수정 필요
  /// 현재는 period에 관계없이 동일한 데이터 범위를 반환하고 있음
  static Future<PortfolioOverviewResponse?> getPortfolioOverview({String period = '1M'}) async {
    try {
      logger.i('포트폴리오 오버뷰 조회 시작 (period: $period)');
      
      final response = await _dio.get(
        '/portfolios/overview',
        queryParameters: {'period': period},
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        logger.i('포트폴리오 오버뷰 조회 성공 (period: $period)');
        final data = response.data;
        if (data is Map && data['history'] is List) {
          final history = data['history'] as List;
          logger.i('응답 데이터 - timeframe: ${data['timeframe']}, history 개수: ${history.length}');
          if (history.isNotEmpty) {
            final first = history.first as Map;
            final last = history.last as Map;
            logger.i('첫 번째 timestamp: ${first['timestamp']}, 마지막 timestamp: ${last['timestamp']}');
          }
        }
        return PortfolioOverviewResponse.fromJson(data);
      } else {
        logger.e('포트폴리오 오버뷰 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('포트폴리오 오버뷰 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 포트폴리오 포지션 조회
  /// [page] - 페이지 번호 (기본값: 0)
  /// [size] - 페이지 크기 (기본값: 10)
  static Future<PortfolioPositionPageResponse?> getPositions({
    int page = 0,
    int size = 10,
  }) async {
    try {
      logger.i('포트폴리오 포지션 조회 시작 (page: $page, size: $size)');
      
      final response = await _dio.get(
        '/portfolios/positions',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      
      if (response.statusCode == 200) {
        logger.i('포트폴리오 포지션 조회 성공');
        return PortfolioPositionPageResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        logger.e('포트폴리오 포지션 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('포트폴리오 포지션 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
      }
      return null;
    }
  }
}

