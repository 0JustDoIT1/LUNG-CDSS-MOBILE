// 기본 스모크 테스트: 앱이 죽지 않고 로그인 화면이 뜨는지만 확인.
// 화면이 늘어나면 각 기능별 테스트 파일을 features/ 구조에 맞춰 추가할 것.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medical_app/app.dart';

void main() {
  testWidgets('앱 실행 시 로그인 화면이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicalApp());
    await tester.pump(); // 첫 프레임 — 스플래시 표시
    await tester.pump(const Duration(milliseconds: 1600)); // 스플래시의 1.5초 지연 경과
    await tester.pumpAndSettle(); // /login으로 전환 완료

    // 카드 타이틀 + 로그인 버튼 라벨, 총 2곳에서 '로그인' 텍스트가 보임
    expect(find.text('로그인'), findsNWidgets(2));
    expect(find.text('의료진용'), findsOneWidget);
    // 이메일/비밀번호 입력창 2개
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
