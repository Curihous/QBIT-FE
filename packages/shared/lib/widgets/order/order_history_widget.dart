import 'package:flutter/material.dart';

// 임시로 주문 내역 위젯을 비활성화
class OrderHistoryWidget extends StatelessWidget {
  const OrderHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Center(
        child: Text('주문 내역 기능은 현재 개발 중입니다'),
      ),
    );
  }
}