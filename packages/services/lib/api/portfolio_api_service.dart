import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/api/api_client.dart';
import 'package:qbit_services/models/portfolio_overview_model.dart';

class PortfolioApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();

  /// 포트폴리오 오버뷰 조회 (90초 캐시)
  static Future<PortfolioOverviewResponse?> getPortfolioOverview() async {
    try {
      logger.i('포트폴리오 오버뷰 조회 시작');
      
      final response = await _dio.get('/portfolios/overview');
      
      if (response.statusCode == 200) {
        logger.i('포트폴리오 오버뷰 조회 성공');
        return PortfolioOverviewResponse.fromJson(response.data);
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
}

