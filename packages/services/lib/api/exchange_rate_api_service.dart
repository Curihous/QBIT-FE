import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 환율 API 

/// - 실시간 USD/KRW 환율 조회 (무료 API 사용)
/// - USD - KRW 양방향 변환
/// - 미국 주식 틱 사이즈($0.01)를 KRW로 변환
/// - API 실패 시 기본 환율(1300원) 
/// - 10분 캐시로 불필요한 API 호출 방지


class ExchangeRateApiService {
  static final Dio _dio = Dio();
  static final Logger logger = Logger();
  
  static const List<String> _apiUrls = [
    'https://api.exchangerate-api.com/v4/latest/USD',
    'https://api.fixer.io/latest?base=USD&symbols=KRW',
    'https://api.currencylayer.com/live?access_key=free&currencies=KRW&source=USD',
  ];
  
  static double? _cachedRate;
  static DateTime? _lastUpdate;
  static const Duration _cacheDuration = Duration(minutes: 10); // 10분 캐시
  static const double _defaultRate = 1300.0; // 기본 환율

  /// USD/KRW 환율 조회
  static Future<double?> getUsdToKrwRate() async {
    try {
      if (_cachedRate != null && 
          _lastUpdate != null && 
          DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
        logger.i('캐시된 환율 사용: $_cachedRate');
        return _cachedRate;
      }

      logger.i('환율 조회 시작');
      
      try {
        final response = await _dio.get('https://api.exchangerate-api.com/v4/latest/USD')
            .timeout(Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && 
              data['rates'] != null && 
              data['rates']['KRW'] != null) {
            final rate = data['rates']['KRW'].toDouble();
            if (rate > 0) {
              _cachedRate = rate;
              _lastUpdate = DateTime.now();
              logger.i('환율 조회 성공: 1 USD = $_cachedRate KRW');
              return _cachedRate;
            }
          }
        }
      } catch (e) {
        logger.w('환율 API 실패, 기본 환율 사용: $e');
      }
      
      // API 실패 시 기본 환율 사용
      _cachedRate = _defaultRate;
      _lastUpdate = DateTime.now();
      logger.i('기본 환율 사용: $_cachedRate KRW');
      return _cachedRate;
      
    } catch (error) {
      logger.e('환율 조회 에러: $error');
      
      // 에러 시 기본 환율 사용
      if (_cachedRate == null) {
        _cachedRate = _defaultRate;
        logger.w('기본 환율 사용: $_cachedRate');
      }
      
      return _cachedRate;
    }
  }

  /// USD를 KRW로 변환
  static Future<double?> usdToKrw(double usdAmount) async {
    final rate = await getUsdToKrwRate();
    if (rate != null) {
      return usdAmount * rate;
    }
    return null;
  }

  /// KRW를 USD로 변환
  static Future<double?> krwToUsd(double krwAmount) async {
    final rate = await getUsdToKrwRate();
    if (rate != null) {
      return krwAmount / rate;
    }
    return null;
  }

  /// 틱 사이즈 계산 (미국 주식은 보통 $0.01)
  static double getTickSize() {
    return 0.01; // $0.01
  }

  /// 틱 사이즈를 KRW로 변환
  static Future<double?> getTickSizeInKrw() async {
    final rate = await getUsdToKrwRate();
    if (rate != null) {
      return getTickSize() * rate;
    }
    return null;
  }
}
