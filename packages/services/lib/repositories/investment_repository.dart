import 'package:qbit_core/models/investment.dart';
import 'package:qbit_core/exceptions/app_exceptions.dart';
import '../api/investment_api_service.dart';

/// 투자 관련 Repository
class InvestmentRepository {
  final InvestmentApiService _investmentApiService = InvestmentApiService();

  /// 주식 목록 조회
  Future<List<Stock>> getStocks({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return await _investmentApiService.getStocks(
        page: page,
        limit: limit,
        search: search,
      );
    } catch (e) {
      throw ApiException(
        message: '주식 목록 조회 실패: $e',
      );
    }
  }

  /// 특정 주식 정보 조회
  Future<Stock> getStock(String symbol) async {
    try {
      return await _investmentApiService.getStock(symbol);
    } catch (e) {
      throw ApiException(
        message: '주식 정보 조회 실패: $e',
      );
    }
  }

  /// 포트폴리오 조회
  Future<Portfolio> getPortfolio() async {
    try {
      return await _investmentApiService.getPortfolio();
    } catch (e) {
      throw ApiException(
        message: '포트폴리오 조회 실패: $e',
      );
    }
  }

  /// 주식 매수
  Future<Map<String, dynamic>> buyStock({
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    try {
      // 유효성 검사
      if (quantity <= 0) {
        throw ValidationException(
          message: '수량은 0보다 커야 합니다',
          field: 'quantity',
        );
      }
      
      if (price <= 0) {
        throw ValidationException(
          message: '가격은 0보다 커야 합니다',
          field: 'price',
        );
      }
      
      return await _investmentApiService.buyStock(
        symbol: symbol,
        quantity: quantity,
        price: price,
      );
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw ApiException(
        message: '주식 매수 실패: $e',
      );
    }
  }

  /// 주식 매도
  Future<Map<String, dynamic>> sellStock({
    required String symbol,
    required int quantity,
    required double price,
  }) async {
    try {
      // 유효성 검사
      if (quantity <= 0) {
        throw ValidationException(
          message: '수량은 0보다 커야 합니다',
          field: 'quantity',
        );
      }
      
      if (price <= 0) {
        throw ValidationException(
          message: '가격은 0보다 커야 합니다',
          field: 'price',
        );
      }
      
      return await _investmentApiService.sellStock(
        symbol: symbol,
        quantity: quantity,
        price: price,
      );
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw ApiException(
        message: '주식 매도 실패: $e',
      );
    }
  }

  /// 거래 내역 조회
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? symbol,
  }) async {
    try {
      return await _investmentApiService.getTransactionHistory(
        page: page,
        limit: limit,
        symbol: symbol,
      );
    } catch (e) {
      throw ApiException(
        message: '거래 내역 조회 실패: $e',
      );
    }
  }
}
