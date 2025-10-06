import 'package:qbit_core/models/investment.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';
import 'base_api_service.dart';

/// 투자 관련 API 서비스
class InvestmentApiService extends BaseApiService {
  /// 주식 목록 조회
  Future<List<Stock>> getStocks({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    
    final response = await get(
      '/stocks',
      queryParameters: queryParameters,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> stocksData = response.data as List<dynamic>;
      return stocksData.map((data) => Stock.fromJson(data as Map<String, dynamic>)).toList();
    }
    
    throw ApiException(
      message: '주식 목록 조회 실패',
      statusCode: response.statusCode,
      endpoint: '/stocks',
    );
  }

  /// 특정 주식 정보 조회
  Future<Stock> getStock(String symbol) async {
    final response = await get('/stocks/$symbol');
    
    if (response.statusCode == 200) {
      return Stock.fromJson(response.data as Map<String, dynamic>);
    }
    
    throw ApiException(
      message: '주식 정보 조회 실패',
      statusCode: response.statusCode,
      endpoint: '/stocks/$symbol',
    );
  }

  /// 포트폴리오 조회
  Future<Portfolio> getPortfolio() async {
    final response = await get('/portfolio');
    
    if (response.statusCode == 200) {
      return Portfolio.fromJson(response.data as Map<String, dynamic>);
    }
    
    throw ApiException(
      message: '포트폴리오 조회 실패',
      statusCode: response.statusCode,
      endpoint: '/portfolio',
    );
  }

  /// 주식 매수
  Future<Map<String, dynamic>> buyStock({
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    final response = await post(
      '/portfolio/buy',
      data: {
        'symbol': symbol,
        'quantity': quantity,
        'price': price,
      },
    );
    
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    
    throw ApiException(
      message: '주식 매수 실패',
      statusCode: response.statusCode,
      endpoint: '/portfolio/buy',
    );
  }

  /// 주식 매도
  Future<Map<String, dynamic>> sellStock({
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    final response = await post(
      '/portfolio/sell',
      data: {
        'symbol': symbol,
        'quantity': quantity,
        'price': price,
      },
    );
    
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
    
    throw ApiException(
      message: '주식 매도 실패',
      statusCode: response.statusCode,
      endpoint: '/portfolio/sell',
    );
  }

  /// 거래 내역 조회
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? symbol,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (symbol != null && symbol.isNotEmpty) {
      queryParameters['symbol'] = symbol;
    }
    
    final response = await get(
      '/transactions',
      queryParameters: queryParameters,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data as List<dynamic>);
    }
    
    throw ApiException(
      message: '거래 내역 조회 실패',
      statusCode: response.statusCode,
      endpoint: '/transactions',
    );
  }
}
