import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/app/app.dart';

void main() {
  testWidgets('숨잇 앱 실행 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const SumItApp());

    expect(find.text('숨잇'), findsOneWidget);
  });
}