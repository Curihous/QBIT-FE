import 'package:flutter/material.dart';

// 임시로 주문 관련 위젯들을 비활성화
class OrderActionSheet extends StatelessWidget {
  final String symbol;
  final String stockName;
  final double currentPrice;

  const OrderActionSheet({
    super.key,
    required this.symbol,
    required this.stockName,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Center(
        child: Text('주문 기능은 현재 개발 중입니다'),
      ),
    );
  }
}