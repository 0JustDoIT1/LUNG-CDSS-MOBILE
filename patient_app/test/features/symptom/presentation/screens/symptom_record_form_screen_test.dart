import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/presentation/screens/symptom_record_form_screen.dart';

void main() {
  testWidgets('keeps submit disabled and explains incomplete symptom input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SymptomRecordFormScreen()),
      ),
    );

    expect(find.text('증상 제출'), findsOneWidget);
    expect(find.text('모든 증상 항목을 선택해 주세요.'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
