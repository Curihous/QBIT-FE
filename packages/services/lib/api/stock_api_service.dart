import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_client.dart';
import '../models/stock_model.dart';
import '../models/asset_model.dart';
import '../models/stock_ranking_model.dart';

/// 주식 관련 API 서비스 모음

class StockApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();

  /// 특정 종목 상세 정보 조회
  static Future<StockModel?> getStockDetail(String symbol) async {
    try {
      logger.i('주식 상세 정보 조회 시작: $symbol');
      
      final response = await _dio.get('/stocks/$symbol');
      
      if (response.statusCode == 200) {
        logger.i('주식 상세 정보 조회 성공: $symbol');
        logger.d('응답 데이터: ${response.data}');
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return StockModel.fromJson(data);
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('주식 상세 정보 조회 실패: ${response.statusCode}');
        logger.e('응답 데이터: ${response.data}');
        return null;
      }
    } catch (error) {
      logger.e('주식 상세 정보 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
        if (error.response?.statusCode == 404) {
          logger.e('❌ 종목을 찾을 수 없습니다: $symbol');
          logger.e('❌ 백엔드에서 Alpaca API를 통해 데이터를 가져오지 못했을 수 있습니다.');
        }
      }
      return null;
    }
  }

  /// 주식 목록 조회
  static Future<List<StockModel>?> getStockList() async {
    try {
      logger.i('주식 목록 조회 시작');
      
      final response = await _dio.get('/stocks');
      
      if (response.statusCode == 200) {
        logger.i('주식 목록 조회 성공');
        final data = response.data;
        if (data is List) {
          return data.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          logger.e('응답 데이터가 List가 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('주식 목록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('주식 목록 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 해외 주요 지수 조회
  static Future<List<StockModel>?> getOverseasIndices() async {
    try {
      logger.i('해외 주요 지수 조회 시작');
      
      final response = await _dio.get('/indices');
      
      if (response.statusCode == 200) {
        logger.i('해외 주요 지수 조회 성공');
        final data = response.data;
        if (data is List) {
          return data.map((json) => StockModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          logger.e('응답 데이터가 List가 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('해외 주요 지수 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('해외 주요 지수 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }


  /// 특정 지수 상세 조회
  static Future<StockModel?> getIndexDetail(String symbol) async {
    try {
      logger.i('지수 상세 조회 시작: $symbol');
      
      final response = await _dio.get('/indices/$symbol');
      
      if (response.statusCode == 200) {
        logger.i('지수 상세 조회 성공: $symbol');
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return StockModel.fromJson(data);
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('지수 상세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('지수 상세 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        if (error.response?.statusCode == 404) {
          logger.e('지수를 찾을 수 없습니다: $symbol');
        }
      }
      return null;
    }
  }

  /// 지수 과거 데이터 조회
  static Future<List<Map<String, dynamic>>?> getIndexHistory(String symbol, {
    String? startDate,
    String? endDate,
    String? timeframe = '1Day',
  }) async {
    try {
      logger.i('지수 과거 데이터 조회 시작: $symbol');
      
      final queryParams = <String, dynamic>{
        'timeframe': timeframe,
      };
      
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _dio.get(
        '/indices/$symbol/history',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        logger.i('지수 과거 데이터 조회 성공: $symbol');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        logger.e('지수 과거 데이터 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('지수 과거 데이터 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        if (error.response?.statusCode == 404) {
          logger.e('지수를 찾을 수 없습니다: $symbol');
        }
      }
      return null;
    }
  }

  /// 보유자산 조회 (Alpaca 계정 정보에서 가져옴)
  static Future<AssetModel?> getUserAssets() async {
    try {
      logger.i('보유자산 조회 시작 (Alpaca 계정 정보에서)');
      
      // Alpaca 계정 정보에서 보유자산 정보 가져오기
      final accountInfo = await getAlpacaAccount();
      
      if (accountInfo != null) {
        logger.i('보유자산 조회 성공 (Alpaca 계정 정보에서)');
        
        // Alpaca 계정 정보를 AssetModel 형태로 변환
        return AssetModel.fromJson({
          'portfolioValue': accountInfo['portfolioValue'] ?? '0',
          'cash': accountInfo['cash'] ?? '0',
          'buyingPower': accountInfo['buyingPower'] ?? '0',
          'equity': accountInfo['equity'] ?? '0',
          'longMarketValue': accountInfo['longMarketValue'] ?? '0',
          'currency': accountInfo['currency'] ?? 'USD',
        });
      } else {
        logger.e('Alpaca 계정 정보 조회 실패');
        return null;
      }
    } catch (error) {
      logger.e('보유자산 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 해외 종목 순위 조회 (공개 API 우선)
  static Future<List<StockRankingModel>?> getOverseasStockRanking({
    String sortBy = 'volume', // volume, gain, loss, surge
  }) async {
    try {
      logger.i('해외 종목 순위 조회 시작: $sortBy');
      
      // 공개 API 엔드포인트 시도
      final response = await _dio.get('/public/stocks/ranking', queryParameters: {
        'sort_by': sortBy,
      });
      
      if (response.statusCode == 200) {
        logger.i('해외 종목 순위 조회 성공 (공개 API): $sortBy');
        final data = response.data;
        if (data is List) {
          return data.map((json) => StockRankingModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          logger.e('응답 데이터가 List가 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('해외 종목 순위 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('해외 종목 순위 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        
        // 공개 API가 없거나 인증이 필요한 경우 인증 API 시도
        if (error.response?.statusCode == 404 || error.response?.statusCode == 401) {
          logger.i('공개 API가 없거나 인증이 필요하므로 인증 API 시도');
          return await _getOverseasStockRankingWithAuth(sortBy: sortBy);
        }
      }
      return null;
    }
  }

  /// 인증이 필요한 해외 종목 순위 조회
  static Future<List<StockRankingModel>?> _getOverseasStockRankingWithAuth({
    String sortBy = 'volume',
  }) async {
    try {
      logger.i('해외 종목 순위 조회 시작 (인증 API): $sortBy');
      
      final response = await _dio.get('/stocks/ranking', queryParameters: {
        'sort_by': sortBy,
      });
      
      if (response.statusCode == 200) {
        logger.i('해외 종목 순위 조회 성공 (인증 API): $sortBy');
        final data = response.data;
        if (data is List) {
          return data.map((json) => StockRankingModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          logger.e('응답 데이터가 List가 아닙니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('해외 종목 순위 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('해외 종목 순위 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
      }
      return null;
    }
  }

  // Alpaca 계정 정보 조회
  static Future<Map<String, dynamic>?> getAlpacaAccount() async {
    try {
      logger.i('Alpaca 계정 정보 조회 시작');
      
      final response = await _dio.get('/alpaca/account');
      
      if (response.statusCode == 200) {
        logger.i('Alpaca 계정 정보 조회 성공');
        logger.d('응답 데이터: ${response.data}');
        
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          logger.e('응답 데이터 타입이 예상과 다름: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('Alpaca 계정 정보 조회 실패: ${response.statusCode}');
        logger.d('응답 데이터: ${response.data}');
        return null;
      }
    } catch (error) {
      logger.e('Alpaca 계정 정보 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
        
        if (error.response?.statusCode == 401) {
          logger.e('401 에러: 인증되지 않은 요청');
        } else if (error.response?.statusCode == 404) {
          logger.e('404 에러: Alpaca 계정이 연결되지 않음');
        }
      }
      return null;
    }
  }

  // 종목 검색
  static Future<List<StockModel>?> searchStocks(String query) async {
    try {
      logger.i('종목 검색 시작: $query');
      
      final response = await _dio.get('/stocks/search', queryParameters: {
        'q': query.toUpperCase(), // 자동으로 대문자 변환
        'assetClass': 'us_equity', // 미국 주식으로 필터링
      });
      
      if (response.statusCode == 200) {
        logger.i('종목 검색 성공');
        logger.d('응답 데이터: ${response.data}');
        logger.i('응답 데이터 타입: ${response.data.runtimeType}');
        logger.i('응답 데이터 길이: ${response.data is List ? (response.data as List).length : 'N/A'}');
        
        if (response.data is List) {
          final List<dynamic> data = response.data as List<dynamic>;
          logger.i('파싱할 데이터 개수: ${data.length}');
          
          if (data.isEmpty) {
            logger.w('⚠️ 검색 결과가 비어있습니다. 쿼리: $query');
            logger.w('⚠️ 백엔드에서 해당 종목이 존재하지 않을 수 있습니다.');
            return [];
          }
          
          return data.map((json) => StockModel.fromJson(json)).toList();
        } else {
          logger.e('응답 데이터 타입이 예상과 다름: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('종목 검색 실패: ${response.statusCode}');
        logger.e('응답 데이터: ${response.data}');
        return null;
      }
    } catch (error) {
      logger.e('종목 검색 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: ${error.response?.data}');
        logger.e('Dio 에러 상태코드: ${error.response?.statusCode}');
        
        if (error.response?.statusCode == 401) {
          logger.e('401 에러: 인증되지 않은 요청');
        } else if (error.response?.statusCode == 404) {
          logger.e('❌ 404 에러: 검색 결과 없음');
        }
      }
      return null;
    }
  }

}
