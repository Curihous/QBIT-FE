import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'api_client.dart';
import '../models/stock_model.dart';
import '../models/asset_model.dart';
import '../models/stock_ranking_model.dart';
import '../models/orderbook_model.dart';
import '../models/candle_model.dart';
import '../models/stock_detail_model.dart';

/// 주식 관련 API 서비스 모음

class StockApiService {
  static Dio get _dio => ApiClient.instance;
  static final Logger logger = Logger();


  /// 주식 목록 조회
  static Future<List<StockModel>?> getStockList() async {
    try {
      final response = await _dio.get('/stocks');
      
      if (response.statusCode == 200) {
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
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 해외 주요 지수 조회
  static Future<List<StockModel>?> getOverseasIndices() async {
    try {
      final response = await _dio.get('/indices');
      
      if (response.statusCode == 200) {
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
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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
          'accountNumber': accountInfo['accountNumber'] ?? '',
          'status': accountInfo['status'] ?? '',
          'currency': accountInfo['currency'] ?? 'USD',
          'buyingPower': accountInfo['buyingPower'] ?? '0',
          'cash': accountInfo['cash'] ?? '0',
          'portfolioValue': accountInfo['portfolioValue'] ?? '0',
          'equity': accountInfo['equity'] ?? '0',
          'lastEquity': accountInfo['lastEquity'] ?? '0',
          'longMarketValue': accountInfo['longMarketValue'] ?? '0',
        });
      } else {
        logger.e('Alpaca 계정 정보 조회 실패');
        return null;
      }
    } catch (error) {
      logger.e('보유자산 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 해외 종목 순위 조회
  /// sortBy: 'volume' (거래량순), 'volatility' (등락폭순), 'moving' (상승률순)
  static Future<List<StockRankingModel>?> getOverseasStockRanking({
    String sortBy = 'volume', // volume, volatility, moving
  }) async {
    try {
      logger.i('해외 종목 순위 조회 시작: $sortBy');
      
      // 엔드포인트 매핑
      String endpoint;
      switch (sortBy) {
        case 'volume':
          endpoint = '/stocks/ranking/volume';
          break;
        case 'volatility':
          endpoint = '/stocks/ranking/volatility';
          break;
        case 'moving':
          endpoint = '/stocks/ranking/moving';
          break;
        default:
          endpoint = '/stocks/ranking/volume';
      }
      
      final response = await _dio.get(endpoint);
      
      if (response.statusCode == 200) {
        logger.i('해외 종목 순위 조회 성공: $sortBy');
        final data = response.data;
        if (data is List) {
          // 상위 20개 반환하고 rank 부여 (1부터 시작) - 5개씩 4페이지로 표시
          final allData = data.take(20).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final json = entry.value as Map<String, dynamic>;
            return StockRankingModel.fromJson(json, rank: index + 1);
          }).toList();
          return allData;
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
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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
        logger.i('응답 데이터: ${response.data}');
        
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          logger.e('응답 데이터 타입이 예상과 다름: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('Alpaca 계정 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('Alpaca 계정 정보 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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
  static Future<List<StockModel>?> searchStocks(String query, {String? assetClass}) async {
    try {
      logger.i('종목 검색 시작: $query, assetClass: $assetClass');
      
      final queryParams = <String, dynamic>{
        'q': query.toUpperCase(), // 자동으로 대문자 변환
      };
      
      // assetClass가 지정된 경우에만 추가
      if (assetClass != null) {
        queryParams['assetClass'] = assetClass;
      }
      
      final response = await _dio.get('/stocks/search', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        logger.i('종목 검색 성공');
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
        return null;
      }
    } catch (error) {
      logger.e('종목 검색 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
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

  // 미국 주식 검색
  static Future<List<StockModel>?> searchUSStocks(String query) async {
    return searchStocks(query, assetClass: 'us_equity');
  }

  // 암호화폐 검색
  static Future<List<StockModel>?> searchCrypto(String query) async {
    return searchStocks(query, assetClass: 'crypto');
  }

  /// 암호화폐 호가창 조회 (스냅샷) - 주문 페이지 초기 로드용
  /// GET /stocks/orderbook/{binanceSymbol}
  static Future<OrderBookModel?> getCryptoOrderBook(String binanceSymbol) async {
    try {
      final response = await _dio.get('/stocks/orderbook/$binanceSymbol');
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data;
          final transformedData = {
            'symbol': data['symbol'],
            'bids': (data['bids'] as List).map((bid) => {
              'price': bid['price'].toString(),
              'quantity': bid['quantity'].toString(),
            }).toList(),
            'asks': (data['asks'] as List).map((ask) => {
              'price': ask['price'].toString(),
              'quantity': ask['quantity'].toString(),
            }).toList(),
          };
          return OrderBookModel.fromJson(transformedData);
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('암호화폐 호가창 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('암호화폐 호가창 조회 에러: $error');
      return null;
    }
  }

  /// 종목 상세 정보 조회
  /// GET /stocks/{symbol}
  static Future<StockDetailModel?> getStockDetail(String symbol) async {
    try {
      logger.i('종목 상세 정보 조회 시작: $symbol');
      
      // 현재 토큰 상태 확인
      final currentToken = await ApiClient.debugTokenStatus();
      
      final response = await _dio.get('/stocks/$symbol');
      
      if (response.statusCode == 200) {
        logger.i('종목 상세 정보 조회 성공');
        logger.i('응답 데이터: ${response.data}');
        
        if (response.data is Map<String, dynamic>) {
          return StockDetailModel.fromJson(response.data as Map<String, dynamic>);
        } else {
          logger.e('응답 데이터 타입이 예상과 다름: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('종목 상세 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('종목 상세 정보 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('Dio 에러 데이터: ${error.response?.data}');
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('요청 헤더: ${error.requestOptions.headers}');
      }
      return null;
    }
  }

  /// 암호화폐 캔들 데이터 조회
  /// GET /stocks/crypto/candle/{binanceSymbol}
  /// startTime, endTime은 optional (둘 다 없으면 최근 데이터 반환)
  /// limit: 기본값 500, 최대 1500
  static Future<CandleResponse?> getCryptoCandles({
    required String binanceSymbol,
    String interval = '1d',
    int? startTime,
    int? endTime,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'interval': interval,
      };
      
      if (startTime != null) {
        queryParams['startTime'] = startTime;
      }
      if (endTime != null) {
        queryParams['endTime'] = endTime;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }
      
      final response = await _dio.get(
        '/stocks/crypto/candle/$binanceSymbol',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return CandleResponse.fromJson(response.data);
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('암호화폐 캔들 데이터 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('암호화폐 캔들 데이터 조회 에러: $error');
      if (error is DioException) {
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('상태코드: ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 미국 주식 캔들 데이터 조회
  /// GET /stocks/us-equity/candle/{ticker}
  static Future<CandleResponse?> getUsStockCandles({
    required String ticker,
    required int multiplier,
    required String timespan,
    required DateTime from,
    required DateTime to,
    bool adjusted = true,
  }) async {
    try {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final queryParams = <String, dynamic>{
        'multiplier': multiplier,
        'timespan': timespan,
        'from': dateFormatter.format(from),
        'to': dateFormatter.format(to),
        'adjusted': adjusted,
      };

      logger.i('미국 주식 캔들 조회: $ticker, params=$queryParams');

      final response = await _dio.get(
        '/stocks/us-equity/candle/$ticker',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return CandleResponse.fromJson(response.data as Map<String, dynamic>);
        } else {
          logger.e('미국 주식 캔들 응답이 Map이 아님: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('미국 주식 캔들 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('미국 주식 캔들 조회 에러: $error');
      if (error is DioException) {
        logger.e('요청 URL: ${error.requestOptions.uri}');
        logger.e('상태코드: ${error.response?.statusCode}');
      }
      return null;
    }
  }

  /// 암호화폐 실시간 시세 조회
  /// GET /stocks/crypto/quote/{binanceSymbol}
  static Future<Map<String, dynamic>?> getCryptoQuote(String binanceSymbol) async {
    try {
      final response = await _dio.get('/stocks/crypto/quote/$binanceSymbol');
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          logger.i('암호화폐 실시간 시세 조회 성공: ${response.data}');
          return response.data as Map<String, dynamic>;
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('암호화폐 실시간 시세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('암호화폐 실시간 시세 조회 에러: $error');
      return null;
    }
  }

  /// 미국 주식 실시간 시세 조회
  /// GET /stocks/us-equity/quote/{ticker}
  static Future<Map<String, dynamic>?> getUsStockQuote(String ticker) async {
    try {
      logger.i('미국 주식 실시간 시세 조회 시작: $ticker');
      
      final response = await _dio.get('/stocks/us-equity/quote/$ticker')
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          logger.i('미국 주식 실시간 시세 조회 성공: ${response.data}');
          return response.data as Map<String, dynamic>;
        } else {
          logger.e('응답 데이터가 Map이 아닙니다: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('미국 주식 실시간 시세 조회 실패: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (error) {
      logger.e('미국 주식 실시간 시세 조회 타임아웃: $error');
      return null;
    } catch (error) {
      logger.e('미국 주식 실시간 시세 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('Dio 에러 데이터: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 보유 종목 리스트 조회
  /// GET /portfolios/positions
  /// marketValue 순으로 정렬된 상위 3개 종목의 심볼 리스트 반환
  /// 페이징 지원: 모든 페이지를 가져와서 전체 종목을 정렬
  static Future<List<String>?> getPositions() async {
    try {
      logger.i('보유 종목 리스트 조회 시작');
      
      List<Map<String, dynamic>> allPositions = [];
      int currentPage = 0;
      bool hasNext = true;
      
      // 페이징 처리: 모든 페이지를 가져옴
      while (hasNext) {
        final response = await _dio.get(
          '/portfolios/positions',
          queryParameters: {
            'page': currentPage,
            'size': 100, // 한 번에 많이 가져오기
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          logger.i('보유 종목 리스트 조회 성공 (페이지 $currentPage)');
          
          List<Map<String, dynamic>> positions = [];
          
          if (response.data is List) {
            // 리스트 형태로 반환되는 경우
            positions = (response.data as List)
                .whereType<Map<String, dynamic>>()
                .toList();
            hasNext = false; // 리스트 형태면 페이징 없음
          } else if (response.data is Map<String, dynamic>) {
            // 페이징된 응답 구조: {currentPage, pageSize, totalElements, totalPages, hasNext, content}
            final data = response.data as Map<String, dynamic>;
            
            if (data['content'] is List) {
              positions = (data['content'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList();
              // hasNext 필드 확인
              hasNext = data['hasNext'] as bool? ?? false;
              // hasNext가 없으면 totalPages와 currentPage로 계산
              if (!hasNext && data['totalPages'] != null && data['currentPage'] != null) {
                final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
                final currentPageNum = (data['currentPage'] as num?)?.toInt() ?? 0;
                hasNext = currentPageNum < totalPages - 1;
              }
            } else if (data['positions'] is List) {
              positions = (data['positions'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList();
              hasNext = false;
            } else {
              // 다른 구조일 수 있음
              logger.w('예상하지 못한 응답 구조: ${data.keys}');
              hasNext = false;
            }
          }
          
          allPositions.addAll(positions);
          
          if (!hasNext || positions.isEmpty) {
            break;
          }
          
          currentPage++;
        } else {
          logger.e('보유 종목 리스트 조회 실패: ${response.statusCode}');
          break;
        }
      }
      
      if (allPositions.isEmpty) {
        logger.i('보유 종목 없음');
        return [];
      }
      
      logger.i('전체 보유 종목 개수: ${allPositions.length}');
      
      // marketValue 순으로 정렬 (내림차순)
      // marketValue는 문자열 또는 숫자로 올 수 있음
      allPositions.sort((a, b) {
        double aValue = 0.0;
        double bValue = 0.0;
        
        // marketValue 파싱 (문자열 또는 숫자)
        if (a['marketValue'] != null) {
          if (a['marketValue'] is num) {
            aValue = (a['marketValue'] as num).toDouble();
          } else if (a['marketValue'] is String) {
            aValue = double.tryParse(a['marketValue'] as String) ?? 0.0;
          }
        }
        
        if (b['marketValue'] != null) {
          if (b['marketValue'] is num) {
            bValue = (b['marketValue'] as num).toDouble();
          } else if (b['marketValue'] is String) {
            bValue = double.tryParse(b['marketValue'] as String) ?? 0.0;
          }
        }
        
        return bValue.compareTo(aValue);
      });
      
      // 상위 3개 종목의 심볼 추출
      final tickers = allPositions
          .take(3)
          .map((item) => item['symbol'] as String?)
          .where((symbol) => symbol != null && symbol.isNotEmpty)
          .cast<String>()
          .toList();
      
      logger.i('상위 3개 종목: $tickers');
      logger.i('상위 3개 종목 상세:');
      for (int i = 0; i < tickers.length && i < allPositions.length; i++) {
        final pos = allPositions[i];
        logger.i('  ${i + 1}. ${pos['symbol']}: marketValue=${pos['marketValue']}');
      }
      
      return tickers;
    } on TimeoutException catch (error) {
      logger.e('보유 종목 리스트 조회 타임아웃: $error');
      return null;
    } catch (error) {
      logger.e('보유 종목 리스트 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('Dio 에러 데이터: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 포지션 상세 정보 조회 (매수 가능 금액 및 보유 수량)
  /// GET /portfolios/positions/detail?symbol={symbol}
  static Future<Map<String, dynamic>?> getPositionDetail(String symbol) async {
    try {
      logger.i('포지션 상세 정보 조회 시작: $symbol');
      
      final response = await _dio.get(
        '/portfolios/positions/detail',
        queryParameters: {'symbol': symbol},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        logger.i('포지션 상세 정보 조회 성공');
        logger.i('응답 데이터: ${response.data}');
        
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          logger.e('응답 데이터 타입이 예상과 다름: ${response.data.runtimeType}');
          return null;
        }
      } else {
        logger.e('포지션 상세 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (error) {
      logger.e('포지션 상세 정보 조회 타임아웃: $error');
      return null;
    } catch (error) {
      logger.e('포지션 상세 정보 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('Dio 에러 데이터: ${error.response?.data}');
      }
      return null;
    }
  }

}
