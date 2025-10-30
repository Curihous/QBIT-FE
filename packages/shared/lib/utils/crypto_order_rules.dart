import 'dart:math';

/// 암호화폐 주문 규칙 및 자동 보정 유틸리티
class CryptoOrderRules {
  final double minOrderSize;
  final double minTradeIncrement; // 수량 증분
  final double priceIncrement;    // 가격 증분
  final int qtyMaxDecimals;       // 수량 최대 소수자리 
  final double minNotionalUSDT;   // 최소 체결금액 (USDT)

  CryptoOrderRules({
    required this.minOrderSize,
    required this.minTradeIncrement,
    required this.priceIncrement,
    this.qtyMaxDecimals = 9,
    this.minNotionalUSDT = 1.0,
  });

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

      // 최소 체결금액 검사
      if (notional < minNotionalUSDT) {
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

  /// ETH/USDT 기본 규칙
  static CryptoOrderRules ethUsdt() {
    return CryptoOrderRules(
      minOrderSize: 0.000223249,
      minTradeIncrement: 0.000000001,
      priceIncrement: 0.01,
      qtyMaxDecimals: 9,
      minNotionalUSDT: 1.0,
    );
  }

  /// BTC/USDT 기본 규칙
  static CryptoOrderRules btcUsdt() {
    return CryptoOrderRules(
      minOrderSize: 0.00001,
      minTradeIncrement: 0.00000001,
      priceIncrement: 0.01,
      qtyMaxDecimals: 8,
      minNotionalUSDT: 1.0,
    );
  }

  /// 심볼에 따른 규칙 반환
  static CryptoOrderRules forSymbol(String symbol) {
    final cleanSymbol = symbol.replaceAll('/', '').toUpperCase();
    
    switch (cleanSymbol) {
      case 'ETHUSDT':
        return ethUsdt();
      case 'BTCUSDT':
        return btcUsdt();
      default:
        // 기본 규칙 (ETH/USDT와 동일)
        return ethUsdt();
    }
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
