/// 날짜 및 시간 관련 유틸리티
class DateUtils {
  /// 현재 날짜를 문자열로 반환
  static String getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// 현재 시간을 문자열로 반환
  static String getCurrentTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
  
  /// 날짜 문자열을 DateTime으로 변환
  static DateTime? parseDateString(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// 두 날짜 사이의 일수 계산
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }
}

/// 문자열 관련 유틸리티
class StringUtils {
  /// 문자열이 비어있거나 null인지 확인
  static bool isEmpty(String? str) {
    return str == null || str.isEmpty;
  }
  
  /// 문자열이 비어있지 않은지 확인
  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty;
  }
  
  /// 문자열을 안전하게 자르기
  static String truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }
  
  /// 숫자 문자열을 천 단위 콤마로 포맷팅
  static String formatNumber(String numberString) {
    try {
      final number = double.parse(numberString);
      return number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return numberString;
    }
  }
}

/// 숫자 관련 유틸리티
class NumberUtils {
  /// 숫자를 안전하게 파싱
  static double? parseDouble(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return double.parse(str);
    } catch (e) {
      return null;
    }
  }
  
  /// 숫자를 안전하게 파싱 (정수)
  static int? parseInt(String? str) {
    if (str == null || str.isEmpty) return null;
    try {
      return int.parse(str);
    } catch (e) {
      return null;
    }
  }
  
  /// 숫자를 퍼센트 문자열로 변환
  static String toPercentage(double value, {int decimalPlaces = 2}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }
  
  /// 숫자를 통화 형식으로 변환
  static String toCurrency(double value, {String symbol = '₩'}) {
    return '$symbol${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
