/// 주식 데이터 모델 클래스
class StockModel {
  final String symbol;
  final String name;
  final String? binanceSymbol;
  final double currentPrice;
  final double changeAmount;
  final double changePercentage;
  final bool isPositive;
  
  // 추가 필드들 (종목 상세 정보)
  final String? exchange;
  final String? assetClass;
  final bool? status;
  final bool? tradable;
  final bool? fractionable;
  final double? minOrderSize;
  final double? minTradeIncrement;
  final double? priceIncrement;
  final String? logoUrl;

  StockModel({
    required this.symbol,
    required this.name,
    this.binanceSymbol,
    this.currentPrice = 0.0,
    this.changeAmount = 0.0,
    this.changePercentage = 0.0,
    this.isPositive = true,
    this.exchange,
    this.assetClass,
    this.status,
    this.tradable,
    this.fractionable,
    this.minOrderSize,
    this.minTradeIncrement,
    this.priceIncrement,
    this.logoUrl,
  });

  /// JSON에서 StockModel 객체 생성
  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      binanceSymbol: json['binanceSymbol'] as String?,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
      isPositive: json['isPositive'] as bool? ?? true,
      exchange: json['exchange'] as String?,
      assetClass: json['assetClass'] as String?,
      status: json['status'] == 'active' || json['status'] == true,
      tradable: json['tradable'] as bool?,
      fractionable: json['fractionable'] as bool?,
      minOrderSize: (json['minOrderSize'] as num?)?.toDouble(),
      minTradeIncrement: (json['minTradeIncrement'] as num?)?.toDouble(),
      priceIncrement: (json['priceIncrement'] as num?)?.toDouble(),
      logoUrl: json['logoUrl'] as String?,
    );
  }

  /// StockModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'binanceSymbol': binanceSymbol,
      'currentPrice': currentPrice,
      'changeAmount': changeAmount,
      'changePercentage': changePercentage,
      'isPositive': isPositive,
      'exchange': exchange,
      'assetClass': assetClass,
      'status': status,
      'tradable': tradable,
      'fractionable': fractionable,
      'minOrderSize': minOrderSize,
      'minTradeIncrement': minTradeIncrement,
      'priceIncrement': priceIncrement,
      'logoUrl': logoUrl,
    };
  }

  // copyWith 메서드 추가
  StockModel copyWith({
    String? symbol,
    String? name,
    String? binanceSymbol,
    double? currentPrice,
    double? changeAmount,
    double? changePercentage,
    bool? isPositive,
    String? exchange,
    String? assetClass,
    bool? status,
    bool? tradable,
    bool? fractionable,
    double? minOrderSize,
    double? minTradeIncrement,
    double? priceIncrement,
    String? logoUrl,
  }) {
    return StockModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      binanceSymbol: binanceSymbol ?? this.binanceSymbol,
      currentPrice: currentPrice ?? this.currentPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercentage: changePercentage ?? this.changePercentage,
      isPositive: isPositive ?? this.isPositive,
      exchange: exchange ?? this.exchange,
      assetClass: assetClass ?? this.assetClass,
      status: status ?? this.status,
      tradable: tradable ?? this.tradable,
      fractionable: fractionable ?? this.fractionable,
      minOrderSize: minOrderSize ?? this.minOrderSize,
      minTradeIncrement: minTradeIncrement ?? this.minTradeIncrement,
      priceIncrement: priceIncrement ?? this.priceIncrement,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  String toString() {
    return 'StockModel(symbol: $symbol, name: $name, currentPrice: $currentPrice, changeAmount: $changeAmount, changePercentage: $changePercentage, isPositive: $isPositive, exchange: $exchange, assetClass: $assetClass, status: $status, tradable: $tradable, fractionable: $fractionable, minOrderSize: $minOrderSize, minTradeIncrement: $minTradeIncrement, priceIncrement: $priceIncrement, logoUrl: $logoUrl)';
  }

  /// Double 값 비교를 위한 epsilon 비교 헬퍼
  static bool _doubleEquals(double? a, double? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    const double epsilon = 1e-9;
    return (a - b).abs() < epsilon;
  }

  /// Double 값을 정규화하여 hashCode 계산에 사용
  static int _normalizedDoubleHashCode(double? value) {
    if (value == null) return 0;
    const double epsilon = 1e-9;
    // epsilon 단위로 반올림하여 정규화
    final normalized = (value / epsilon).round() * epsilon;
    return normalized.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StockModel &&
        other.symbol == symbol &&
        other.name == name &&
        _doubleEquals(other.currentPrice, currentPrice) &&
        _doubleEquals(other.changeAmount, changeAmount) &&
        _doubleEquals(other.changePercentage, changePercentage) &&
        other.isPositive == isPositive &&
        other.exchange == exchange &&
        other.assetClass == assetClass &&
        other.status == status &&
        other.tradable == tradable &&
        other.fractionable == fractionable &&
        _doubleEquals(other.minOrderSize, minOrderSize) &&
        _doubleEquals(other.minTradeIncrement, minTradeIncrement) &&
        _doubleEquals(other.priceIncrement, priceIncrement) &&
        other.logoUrl == logoUrl;
  }

  @override
  int get hashCode {
    return symbol.hashCode ^
        name.hashCode ^
        _normalizedDoubleHashCode(currentPrice) ^
        _normalizedDoubleHashCode(changeAmount) ^
        _normalizedDoubleHashCode(changePercentage) ^
        isPositive.hashCode ^
        exchange.hashCode ^
        assetClass.hashCode ^
        status.hashCode ^
        tradable.hashCode ^
        fractionable.hashCode ^
        _normalizedDoubleHashCode(minOrderSize) ^
        _normalizedDoubleHashCode(minTradeIncrement) ^
        _normalizedDoubleHashCode(priceIncrement) ^
        logoUrl.hashCode;
  }
}