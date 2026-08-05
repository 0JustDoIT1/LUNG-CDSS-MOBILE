import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/data/models/medication_log.dart';
import 'package:patient_app/features/symptom/data/models/symptom_record.dart';
import 'package:patient_app/features/symptom/presentation/providers/symptom_medication_provider.dart';
import 'package:patient_app/features/symptom/presentation/screens/symptom_medication_screen.dart';

void main() {
  testWidgets('keeps the symptom record action with an empty API list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayMedicationLogsProvider.overrideWith(
            (ref) async => <MedicationLog>[],
          ),
          symptomRecordsProvider.overrideWith((ref) async => <SymptomRecord>[]),
        ],
        child: const MaterialApp(home: SymptomMedicationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('작성된 증상 기록이 없습니다.'), findsOneWidget);
    expect(find.text('새 증상 기록 작성'), findsOneWidget);
  });
}
