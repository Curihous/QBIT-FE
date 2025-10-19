import 'package:json_annotation/json_annotation.dart';
import 'dart:math';

part 'stock_detail_model.g.dart';

@JsonSerializable()
class StockDetailModel {
  final String symbol;
  final String name;
  final String exchange;
  final String assetClass;
  final bool status;
  final bool tradable;
  final String fractionable;
  final String? minOrderSize;
  final String? minTradeIncrement;
  final String? priceIncrement;
  final String? logoUrl;

  StockDetailModel({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.assetClass,
    required this.status,
    required this.tradable,
    required this.fractionable,
    this.minOrderSize,
    this.minTradeIncrement,
    this.priceIncrement,
    this.logoUrl,
  });

  factory StockDetailModel.fromJson(Map<String, dynamic> json) => _$StockDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$StockDetailModelToJson(this);

  /// 암호화폐인지 확인
  bool get isCrypto => assetClass == 'crypto';

  /// 미국 주식인지 확인
  bool get isUsEquity => assetClass == 'us_equity';

  /// 최소 주문 수량 (double)
  double? get minOrderSizeAsDouble => minOrderSize != null ? double.tryParse(minOrderSize!) : null;

  /// 최소 거래 증분 (double)
  double? get minTradeIncrementAsDouble => minTradeIncrement != null ? double.tryParse(minTradeIncrement!) : null;

  /// 가격 증분 (double)
  double? get priceIncrementAsDouble => priceIncrement != null ? double.tryParse(priceIncrement!) : null;

  /// 주문 규칙 생성
  OrderRules toOrderRules() {
    if (isCrypto) {
      return OrderRules.crypto(
        minOrderSize: minOrderSizeAsDouble ?? 0.000223249,
        minTradeIncrement: minTradeIncrementAsDouble ?? 0.000000001,
        priceIncrement: priceIncrementAsDouble ?? 0.01,
        minNotionalUSDT: 1.0,
      );
    } else if (isUsEquity) {
      return OrderRules.usEquity();
    } else {
      // 기본 규칙 (암호화폐와 동일)
      return OrderRules.crypto(
        minOrderSize: 0.000223249,
        minTradeIncrement: 0.000000001,
        priceIncrement: 0.01,
        minNotionalUSDT: 1.0,
      );
    }
  }
}

/// 주문 규칙 클래스 (기존 CryptoOrderRules를 확장)
class OrderRules {
  final double minOrderSize;
  final double minTradeIncrement; // 수량 증분
  final double priceIncrement;    // 가격 증분
  final int qtyMaxDecimals;       // 수량 최대 소수자리
  final double minNotionalUSDT;  // 최소 체결금액 (USDT)
  final bool isCrypto;

  OrderRules({
    required this.minOrderSize,
    required this.minTradeIncrement,
    required this.priceIncrement,
    this.qtyMaxDecimals = 9,
    this.minNotionalUSDT = 10.0, // Alpaca 최소 주문 금액: $10
    this.isCrypto = true,
  });

  /// 암호화폐 규칙 생성
  factory OrderRules.crypto({
    required double minOrderSize,
    required double minTradeIncrement,
    required double priceIncrement,
    double minNotionalUSDT = 1.0,
    int qtyMaxDecimals = 9,
  }) {
    return OrderRules(
      minOrderSize: minOrderSize,
      minTradeIncrement: minTradeIncrement,
      priceIncrement: priceIncrement,
      qtyMaxDecimals: qtyMaxDecimals,
      minNotionalUSDT: minNotionalUSDT,
      isCrypto: true,
    );
  }

  /// 미국 주식 규칙 생성
  factory OrderRules.usEquity() {
    return OrderRules(
      minOrderSize: 1.0, // 주식은 최소 1주
      minTradeIncrement: 0.000000001, // 소수 9자리까지 허용
      priceIncrement: 0.01, // 가격 증분 0.01
      qtyMaxDecimals: 9,
      minNotionalUSDT: 1.0, // 최소 1달러
      isCrypto: false,
    );
  }

  /// 값을 증분 단위로 올림
  static double roundUpToStep(double value, double step) {
    final n = (value / step).ceil();
    return n * step;
  }

  /// 값을 증분 단위로 반올림
  static double roundToStep(double value, double step) {
    final n = (value / step).roundToDouble();
    return n * step;
  }

  /// 지정가 주문에서 통과되는 최소 수량 계산
  double minPassingQtyAtPrice(double price) {
    if (!isCrypto) {
      // 주식은 최소 주문 수량만 확인
      return minOrderSize;
    }

    // 최소 체결금액을 만족하는 수량 계산
    final needQty = roundUpToStep(minNotionalUSDT / price, minTradeIncrement);
    
    // 최소 주문 수량과 비교하여 더 큰 값 선택
    final qty = (needQty > minOrderSize) ? needQty : minOrderSize;
    
    // 소수 자릿수 제한 적용
    final factor = pow(10, qtyMaxDecimals).toDouble();
    return (qty * factor).floor() / factor;
  }

  /// 가격을 증분 단위로 정규화
  double normalizePrice(double price) {
    return roundToStep(price, priceIncrement);
  }

  /// 수량을 증분 단위로 정규화
  double normalizeQuantity(double quantity) {
    final normalized = roundUpToStep(quantity, minTradeIncrement);
    final factor = pow(10, qtyMaxDecimals).toDouble();
    return (normalized * factor).floor() / factor;
  }

  /// 주문 유효성 검사
  OrderValidationResult validateOrder({
    required double quantity,
    required double price,
    required bool isMarketOrder,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (isMarketOrder) {
      // 시장가 주문 검사
      if (quantity <= 0) {
        errors.add('수량은 0보다 커야 합니다');
      }
    } else {
      // 지정가 주문 검사
      final normalizedPrice = normalizePrice(price);
      final normalizedQty = normalizeQuantity(quantity);
      final notional = normalizedQty * normalizedPrice;

      // 최소 주문 수량 검사
      if (normalizedQty < minOrderSize) {
        errors.add('최소 주문 수량: ${minOrderSize.toStringAsFixed(9)}');
      }

      // 최소 체결금액 검사 (암호화폐만)
      if (isCrypto && notional < minNotionalUSDT) {
        errors.add('최소 체결금액: ${minNotionalUSDT} USDT');
        warnings.add('권장 수량: ${minPassingQtyAtPrice(normalizedPrice).toStringAsFixed(9)}');
      }

      // 가격 증분 검사
      if ((price / priceIncrement).roundToDouble() * priceIncrement != price) {
        warnings.add('가격이 증분 단위(${priceIncrement})에 맞지 않습니다');
      }

      // 수량 증분 검사
      if ((quantity / minTradeIncrement).roundToDouble() * minTradeIncrement != quantity) {
        warnings.add('수량이 증분 단위(${minTradeIncrement})에 맞지 않습니다');
      }
    }

    return OrderValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestedQuantity: isMarketOrder ? null : minPassingQtyAtPrice(normalizePrice(price)),
      suggestedPrice: isMarketOrder ? null : normalizePrice(price),
    );
  }
}

/// 주문 유효성 검사 결과
class OrderValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final double? suggestedQuantity;
  final double? suggestedPrice;

  OrderValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.suggestedQuantity,
    this.suggestedPrice,
  });

  @override
  String toString() {
    return 'OrderValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}
