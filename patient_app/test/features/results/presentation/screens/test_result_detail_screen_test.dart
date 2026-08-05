import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/results/data/models/patient_result.dart';
import 'package:patient_app/features/results/presentation/providers/test_result_provider.dart';
import 'package:patient_app/features/results/presentation/screens/test_result_detail_screen.dart';

void main() {
  testWidgets(
    'shows gene likelihoods but hides subtype probabilities and note',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testResultDetailProvider(
              'case-uuid',
            ).overrideWith((ref) async => _result),
          ],
          child: const MaterialApp(
            home: TestResultDetailScreen(resultId: 'case-uuid'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('폐선암(LUAD)으로 확인되었습니다.'), findsOneWidget);
      expect(find.text('TP53'), findsOneWidget);
      expect(find.text('유전자 변이 확률'), findsOneWidget);
      expect(find.text('의료진 소견'), findsNothing);
      expect(find.text('internal doctor note'), findsNothing);
      expect(find.text('81%'), findsNothing);
      expect(find.text('19%'), findsNothing);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('73%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('확률 정보 없음'), findsOneWidget);
      expect(find.text('유전자 정보 확인 필요'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('keeps the empty gene prediction message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          testResultDetailProvider(
            'empty-case',
          ).overrideWith((ref) async => _emptyGeneResult),
        ],
        child: const MaterialApp(
          home: TestResultDetailScreen(resultId: 'empty-case'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('유전자 변이 확률'), findsOneWidget);
    expect(find.text('유전자 예측 정보가 없습니다.'), findsOneWidget);
  });

  testWidgets('shows the patient-specific 403 message and retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          testResultDetailProvider('case-uuid').overrideWithValue(
            AsyncValue<PatientResult>.error(
              const ApiException(message: 'forbidden', statusCode: 403),
              StackTrace.empty,
            ),
          ),
        ],
        child: const MaterialApp(
          home: TestResultDetailScreen(resultId: 'case-uuid'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('검사결과를 조회할 권한이 없습니다.'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('shows the patient-specific 404 explanation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          testResultDetailProvider('case-uuid').overrideWithValue(
            AsyncValue<PatientResult>.error(
              const ApiException(message: 'not found', statusCode: 404),
              StackTrace.empty,
            ),
          ),
        ],
        child: const MaterialApp(
          home: TestResultDetailScreen(resultId: 'case-uuid'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공개된 검사결과를 찾을 수 없습니다.'), findsOneWidget);
    expect(find.text('결과가 아직 확정되지 않았거나 공개 상태가 아닐 수 있습니다.'), findsOneWidget);
  });
}

const _result = PatientResult(
  caseId: 'case-uuid',
  specimenId: 'SPEC-001',
  finalSubtype: 'LUAD',
  finalNote: 'internal doctor note',
  luadProbability: 0.81,
  luscProbability: 0.19,
  genePredictions: [
    GenePrediction(geneName: 'TP53', likelihood: 0.72),
    GenePrediction(geneName: 'KRAS', likelihood: 0.725),
    GenePrediction(geneName: 'EGFR', likelihood: 0.0),
    GenePrediction(geneName: 'ALK', likelihood: 1.0),
    GenePrediction(geneName: 'ROS1', likelihood: null),
    GenePrediction(geneName: '', likelihood: 0.4),
  ],
  isReleased: true,
  confirmedAt: null,
  releasedAt: null,
);

const _emptyGeneResult = PatientResult(
  caseId: 'empty-case',
  specimenId: 'SPEC-EMPTY',
  finalSubtype: 'LUSC',
  finalNote: 'must stay hidden',
  luadProbability: 0.2,
  luscProbability: 0.8,
  genePredictions: [],
  isReleased: true,
  confirmedAt: null,
  releasedAt: null,
);
