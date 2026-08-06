import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/presentation/screens/symptom_record_form_screen.dart';

void main() {
  testWidgets('keeps submit disabled and explains incomplete symptom input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SymptomRecordFormScreen())),
    );

    expect(find.textContaining('본인의 증상 기록'), findsOneWidget);

    final buttonText = find.text('증상 기록 저장');
    await tester.scrollUntilVisible(
      buttonText,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(buttonText, findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final memoField = tester.widget<TextField>(find.byType(TextField));
    expect(memoField.maxLength, 2000);

    expect(find.text('모든 증상 항목을 선택해 주세요.'), findsOneWidget);

    final filledButtonFinder = find.ancestor(
      of: buttonText,
      matching: find.byType(FilledButton),
    );
    expect(filledButtonFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(filledButtonFinder);
    expect(button.onPressed, isNull);
  });
}
