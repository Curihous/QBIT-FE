/// 보유자산 데이터 모델 클래스 (Alpaca 계정 정보 기반)
class AssetModel {
  final String accountNumber;
  final String status;
  final String currency;
  final double buyingPower;
  final double cash;
  final double portfolioValue;
  final double equity;
  final double lastEquity;
  final double longMarketValue;

  AssetModel({
    required this.accountNumber,
    required this.status,
    required this.currency,
    required this.buyingPower,
    required this.cash,
    required this.portfolioValue,
    required this.equity,
    required this.lastEquity,
    required this.longMarketValue,
  });

  /// JSON에서 AssetModel 객체 생성
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      accountNumber: json['accountNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      buyingPower: double.tryParse(json['buyingPower']?.toString() ?? '0') ?? 0.0,
      cash: double.tryParse(json['cash']?.toString() ?? '0') ?? 0.0,
      portfolioValue: double.tryParse(json['portfolioValue']?.toString() ?? '0') ?? 0.0,
      equity: double.tryParse(json['equity']?.toString() ?? '0') ?? 0.0,
      lastEquity: double.tryParse(json['lastEquity']?.toString() ?? '0') ?? 0.0,
      longMarketValue: double.tryParse(json['longMarketValue']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// AssetModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'accountNumber': accountNumber,
      'status': status,
      'currency': currency,
      'buyingPower': buyingPower,
      'cash': cash,
      'portfolioValue': portfolioValue,
      'equity': equity,
      'lastEquity': lastEquity,
      'longMarketValue': longMarketValue,
    };
  }

  /// 복사본 생성 (일부 필드 변경 가능)
  AssetModel copyWith({
    String? accountNumber,
    String? status,
    String? currency,
    double? buyingPower,
    double? cash,
    double? portfolioValue,
    double? equity,
    double? lastEquity,
    double? longMarketValue,
  }) {
    return AssetModel(
      accountNumber: accountNumber ?? this.accountNumber,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      buyingPower: buyingPower ?? this.buyingPower,
      cash: cash ?? this.cash,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      equity: equity ?? this.equity,
      lastEquity: lastEquity ?? this.lastEquity,
      longMarketValue: longMarketValue ?? this.longMarketValue,
    );
  }

  @override
  String toString() {
    return 'AssetModel(accountNumber: $accountNumber, status: $status, currency: $currency, buyingPower: $buyingPower, cash: $cash, portfolioValue: $portfolioValue, equity: $equity, lastEquity: $lastEquity, longMarketValue: $longMarketValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssetModel &&
        other.accountNumber == accountNumber &&
        other.status == status &&
        other.currency == currency &&
        other.buyingPower == buyingPower &&
        other.cash == cash &&
        other.portfolioValue == portfolioValue &&
        other.equity == equity &&
        other.lastEquity == lastEquity &&
        other.longMarketValue == longMarketValue;
  }

  @override
  int get hashCode {
    return accountNumber.hashCode ^
        status.hashCode ^
        currency.hashCode ^
        buyingPower.hashCode ^
        cash.hashCode ^
        portfolioValue.hashCode ^
        equity.hashCode ^
        lastEquity.hashCode ^
        longMarketValue.hashCode;
  }
}

