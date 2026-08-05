import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/intake/data/intake_api.dart';
import 'package:patient_app/features/intake/data/intake_repository.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';
import 'package:patient_app/features/intake/presentation/providers/intake_form_provider.dart';
import 'package:patient_app/features/intake/presentation/screens/intake_form_screen.dart';

void main() {
  testWidgets('shows server questions, required label, and save action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Repository(_form)));
    await tester.pumpAndSettle();

    expect(find.text('흡연 상태'), findsOneWidget);
    expect(find.text('비흡연'), findsOneWidget);
    expect(find.text('필수'), findsOneWidget);
    expect(find.text('임시저장'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);

    await tester.tap(find.text('비흡연'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('현재 증상'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('추가 내용'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('제출'), findsOneWidget);
  });

  testWidgets('shows the empty question message', (tester) async {
    await tester.pumpWidget(_app(_Repository(_emptyForm)));
    await tester.pumpAndSettle();
    expect(find.text('등록된 문진 문항이 없습니다.'), findsOneWidget);
  });

  testWidgets('keeps retry on a loading error', (tester) async {
    await tester.pumpWidget(_app(_Repository(_form, shouldFail: true)));
    await tester.pumpAndSettle();
    expect(find.text('문진표를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

Widget _app(IntakeRepository repository) {
  return ProviderScope(
    overrides: [intakeRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: IntakeFormScreen(onCompleted: () {})),
  );
}

class _Repository extends IntakeRepository {
  _Repository(this.form, {this.shouldFail = false})
    : super(IntakeApi(ApiClient(dio: Dio())));

  final IntakeForm form;
  final bool shouldFail;

  @override
  Future<IntakeForm> fetchMyIntake() async {
    if (shouldFail) throw Exception('failed');
    return form;
  }
}

final _form = IntakeForm(
  id: 'intake-id',
  content: const IntakeContent(
    status: IntakeStatus.draft,
    questions: <IntakeQuestion>[
      IntakeQuestion(
        questionId: 'smoking',
        questionText: '흡연 상태',
        questionType: IntakeQuestionType.singleChoice,
        options: <String>['비흡연', '현재 흡연'],
        required: true,
        answer: null,
      ),
      IntakeQuestion(
        questionId: 'symptoms',
        questionText: '현재 증상',
        questionType: IntakeQuestionType.multipleChoice,
        options: <String>['기침', '발열'],
        required: false,
        answer: null,
      ),
      IntakeQuestion(
        questionId: 'memo',
        questionText: '추가 내용',
        questionType: IntakeQuestionType.text,
        options: <String>[],
        required: false,
        answer: null,
      ),
    ],
  ),
  submittedAt: null,
  updatedAt: DateTime(2026, 8, 5),
);

final _emptyForm = IntakeForm(
  id: 'intake-id',
  content: const IntakeContent(
    status: IntakeStatus.draft,
    questions: <IntakeQuestion>[],
  ),
  submittedAt: null,
  updatedAt: DateTime(2026, 8, 5),
);
