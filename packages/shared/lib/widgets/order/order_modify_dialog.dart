import 'package:flutter/material.dart';

// 임시로 주문 수정 다이얼로그를 비활성화
class OrderModifyDialog extends StatelessWidget {
  const OrderModifyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('주문 수정'),
      content: Text('주문 수정 기능은 현재 개발 중입니다'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('확인'),
        ),
      ],
    );
  }
}