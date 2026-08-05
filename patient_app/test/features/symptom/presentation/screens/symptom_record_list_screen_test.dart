import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/models/symptom_record.dart';
import 'package:patient_app/features/symptom/presentation/providers/symptom_medication_provider.dart';
import 'package:patient_app/features/symptom/presentation/screens/symptom_record_list_screen.dart';

void main() {
  testWidgets('shows loading while symptom records are pending', (
    tester,
  ) async {
    final completer = Completer<List<SymptomRecord>>();
    await tester.pumpWidget(_app(() => completer.future));

    expect(find.text('증상 기록을 불러오는 중입니다.'), findsOneWidget);

    completer.complete(<SymptomRecord>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the existing empty state for an empty array', (
    tester,
  ) async {
    await tester.pumpWidget(_app(() async => <SymptomRecord>[]));
    await tester.pumpAndSettle();

    expect(find.text('작성된 증상 기록이 없습니다.'), findsOneWidget);
    expect(find.text('아직 기록된 증상이 없습니다.'), findsOneWidget);
  });

  testWidgets('shows risk labels, dates, and nurse review states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        () async => <SymptomRecord>[
          _record(riskLevel: 'green', nurseReviewed: false),
          _record(riskLevel: 'yellow', nurseReviewed: true, day: 4),
          _record(riskLevel: 'red', nurseReviewed: false, day: 3),
          _record(riskLevel: 'unknown', nurseReviewed: false, day: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026.08.05 15:30'), findsOneWidget);
    expect(find.text('낮은 위험'), findsOneWidget);
    expect(find.text('주의'), findsOneWidget);
    expect(find.text('위험'), findsOneWidget);
    expect(find.text('위험도 확인 필요'), findsOneWidget);
    expect(find.text('간호사 확인 완료'), findsOneWidget);
    expect(find.text('확인 대기'), findsNWidgets(3));
    expect(find.textContaining('기침 약간'), findsWidgets);
  });

  testWidgets('shows the 403 message and keeps retry', (tester) async {
    await tester.pumpWidget(
      _app(
        () async =>
            throw const ApiException(message: 'forbidden', statusCode: 403),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('증상 기록을 조회할 권한이 없습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

Widget _app(Future<List<SymptomRecord>> Function() loader) {
  return ProviderScope(
    overrides: [symptomRecordsProvider.overrideWith((ref) => loader())],
    child: const MaterialApp(home: SymptomRecordListScreen()),
  );
}

SymptomRecord _record({
  required String riskLevel,
  required bool nurseReviewed,
  int day = 5,
}) {
  return SymptomRecord(
    id: '$riskLevel-$day',
    patientName: '홍길동',
    checkedAt: DateTime(2026, 8, day, 15, 30),
    symptoms: const SymptomAnswers(
      cough: '약간',
      dyspnea: '활동시만',
      hemoptysis: '없음',
      chestPain: '없음',
      fever: '없음',
      weightLoss: '없음',
      appetite: '평소와 같음',
      fatigue: '약간',
    ),
    riskLevel: riskLevel,
    visibleToNurse: true,
    nurseReviewed: nurseReviewed,
    nurseReviewedAt: nurseReviewed ? DateTime(2026, 8, day, 16) : null,
  );
}
