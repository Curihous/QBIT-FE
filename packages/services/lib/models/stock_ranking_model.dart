/// 종목 순위 데이터 모델 클래스
class StockRankingModel {
  final int rank;
  final String symbol;
  final String name;
  final double price;
  final double changeAmount;
  final double changePercentage;
  final bool isPositive;
  final bool isHighlighted; // 순위에서 강조 표시 여부

  StockRankingModel({
    required this.rank,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changeAmount,
    required this.changePercentage,
    required this.isPositive,
    this.isHighlighted = false,
  });

  /// JSON에서 StockRankingModel 객체 생성
  factory StockRankingModel.fromJson(Map<String, dynamic> json) {
    return StockRankingModel(
      rank: json['rank'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
      isPositive: json['isPositive'] as bool,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
    );
  }

  /// StockRankingModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'symbol': symbol,
      'name': name,
      'price': price,
      'changeAmount': changeAmount,
      'changePercentage': changePercentage,
      'isPositive': isPositive,
      'isHighlighted': isHighlighted,
    };
  }

  /// 복사본 생성 (일부 필드 변경 가능)
  StockRankingModel copyWith({
    int? rank,
    String? symbol,
    String? name,
    double? price,
    double? changeAmount,
    double? changePercentage,
    bool? isPositive,
    bool? isHighlighted,
  }) {
    return StockRankingModel(
      rank: rank ?? this.rank,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercentage: changePercentage ?? this.changePercentage,
      isPositive: isPositive ?? this.isPositive,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  @override
  String toString() {
    return 'StockRankingModel(rank: $rank, symbol: $symbol, name: $name, price: $price, changeAmount: $changeAmount, changePercentage: $changePercentage, isPositive: $isPositive, isHighlighted: $isHighlighted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockRankingModel &&
        other.rank == rank &&
        other.symbol == symbol &&
        other.name == name &&
        other.price == price &&
        other.changeAmount == changeAmount &&
        other.changePercentage == changePercentage &&
        other.isPositive == isPositive &&
        other.isHighlighted == isHighlighted;
  }

  @override
  int get hashCode {
    return rank.hashCode ^
        symbol.hashCode ^
        name.hashCode ^
        price.hashCode ^
        changeAmount.hashCode ^
        changePercentage.hashCode ^
        isPositive.hashCode ^
        isHighlighted.hashCode;
  }
}

