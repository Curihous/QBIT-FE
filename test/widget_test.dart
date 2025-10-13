import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qbit_shared/main.dart';

void main() {
  testWidgets('QBit App 초기화 테스트', (WidgetTester tester) async {
    // 앱 빌드
    await tester.pumpWidget(QbitApp());
    
    // 초기 로딩 화면 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
