/// 주식 가격 파싱 유틸리티
class StockPriceParser {
  /// API 응답에서 currentPrice를 안전하게 파싱
  /// 
  /// [quote] API 응답 맵에서 'currentPrice' 필드를 추출하여 double로 변환
  /// 숫자 타입이거나 문자열일 수 있으므로 모두 처리
  /// 
  /// Returns 파싱된 가격 (null이거나 0 이하면 null 반환)
  static double? parseCurrentPrice(Map<String, dynamic>? quote) {
    if (quote == null || quote['currentPrice'] == null) {
      return null;
    }
    
    final priceValue = quote['currentPrice'];
    
    if (priceValue is num) {
      final price = priceValue.toDouble();
      return price > 0 ? price : null;
    }
    
    if (priceValue is String) {
      final price = double.tryParse(priceValue);
      return price != null && price > 0 ? price : null;
    }
    
    // 기타 타입의 경우 toString()으로 시도
    final price = double.tryParse(priceValue.toString());
    return price != null && price > 0 ? price : null;
  }

  /// 일반적인 숫자 파싱 (기본값 0.0)
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

