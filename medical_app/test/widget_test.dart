// 기본 스모크 테스트: 앱이 죽지 않고 로그인 화면이 뜨는지만 확인.
// 화면이 늘어나면 각 기능별 테스트 파일을 features/ 구조에 맞춰 추가할 것.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_app/app.dart';

void main() {
  testWidgets('앱 실행 시 로그인 화면이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicalApp());
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
    expect(find.text('의사로 로그인'), findsOneWidget);
    expect(find.text('간호사로 로그인'), findsOneWidget);
  });
}
