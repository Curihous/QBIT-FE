import 'dart:math';

/// 가짜 호가창 레벨 데이터
class PseudoOrderBookLevel {
  final double price;
  final bool isBid;
  final bool isMid;
  final double volumeFactor; // 0.0 ~ 1.0
  final double percentFromReference;

  PseudoOrderBookLevel({
    required this.price,
    required this.isBid,
    required this.isMid,
    required this.volumeFactor,
    required this.percentFromReference,
  });
}

/// 미국 주식용 가짜 호가창 생성기
/// 
/// REST API 폴백 시 현재 가격과 거래량을 기반으로 호가창 데이터를 생성합니다.
class UsStockOrderBookGenerator {
  final double midPrice;
  final double referencePrice;
  final double lastVolume;
  final int levelsPerSide;
  final Random _random = Random();

  UsStockOrderBookGenerator({
    required this.midPrice,
    required this.referencePrice,
    required this.lastVolume,
    this.levelsPerSide = 8,
  });

  /// 호가창 레벨 생성
  /// 
  /// [jitter] 값이 클수록 거래량 분포가 더 랜덤하게 변동합니다 (0.0 ~ 1.0)
  List<PseudoOrderBookLevel> generate({double jitter = 0.0}) {
    final levels = <PseudoOrderBookLevel>[];
    
    // 가격 증분 (주식은 일반적으로 $0.01 단위)
    const double priceIncrement = 0.01;
    
    // 매도호가 생성 (현재가보다 높은 가격)
    for (int i = 1; i <= levelsPerSide; i++) {
      final price = midPrice + (i * priceIncrement);
      final percentFromRef = ((price - referencePrice) / referencePrice) * 100;
      
      // 거래량 팩터: 가격이 멀수록 작아지고, jitter로 랜덤 변동 추가
      final baseFactor = 1.0 / (i + 1); // 거리가 멀수록 작아짐
      final jitterFactor = 1.0 + (jitter * (_random.nextDouble() * 0.4 - 0.2)); // ±20% 변동
      final volumeFactor = (baseFactor * jitterFactor).clamp(0.1, 1.0);
      
      levels.add(PseudoOrderBookLevel(
        price: price,
        isBid: false,
        isMid: false,
        volumeFactor: volumeFactor,
        percentFromReference: percentFromRef,
      ));
    }
    
    // 현재가 레벨 (중간)
    levels.add(PseudoOrderBookLevel(
      price: midPrice,
      isBid: false, // 중간은 매도로 표시 (일반적으로)
      isMid: true,
      volumeFactor: 1.0,
      percentFromReference: 0.0,
    ));
    
    // 매수호가 생성 (현재가보다 낮은 가격)
    for (int i = levelsPerSide; i >= 1; i--) {
      final price = midPrice - (i * priceIncrement);
      final percentFromRef = ((price - referencePrice) / referencePrice) * 100;
      
      // 거래량 팩터: 가격이 멀수록 작아지고, jitter로 랜덤 변동 추가
      final baseFactor = 1.0 / (i + 1);
      final jitterFactor = 1.0 + (jitter * (_random.nextDouble() * 0.4 - 0.2));
      final volumeFactor = (baseFactor * jitterFactor).clamp(0.1, 1.0);
      
      levels.add(PseudoOrderBookLevel(
        price: price,
        isBid: true,
        isMid: false,
        volumeFactor: volumeFactor,
        percentFromReference: percentFromRef,
      ));
    }
    
    // 가격 순으로 정렬 (높은 가격부터)
    levels.sort((a, b) => b.price.compareTo(a.price));
    
    return levels;
  }
}

