import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/medication/presentation/screens/medication_management_screen.dart';
import 'package:patient_app/features/symptom/data/models/medication_log.dart';
import 'package:patient_app/features/symptom/presentation/providers/symptom_medication_provider.dart';

void main() {
  testWidgets('refreshes server medication logs when the screen opens', (
    tester,
  ) async {
    var fetchCount = 0;
    final container = ProviderContainer(
      overrides: [
        todayMedicationLogsProvider.overrideWith((ref) async {
          fetchCount += 1;
          return <MedicationLog>[];
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(todayMedicationLogsProvider.future);
    expect(fetchCount, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MedicationManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(fetchCount, 2);
    expect(find.text('오늘 예정된 복약이 없습니다.'), findsOneWidget);
  });
}
