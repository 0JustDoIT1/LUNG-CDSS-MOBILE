import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/intake/data/intake_api.dart';
import 'package:patient_app/features/intake/data/intake_repository.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';
import 'package:patient_app/features/intake/presentation/providers/intake_form_provider.dart';

void main() {
  test('loads data and saves draft answers', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(intakeFormProvider.future);
    final notifier = container.read(intakeFormProvider.notifier);
    expect(notifier.updateAnswer('smoking', '비흡연'), isTrue);
    expect(await notifier.saveDraft(), isTrue);
    expect(repository.savedContents.single.status, IntakeStatus.draft);
    expect(repository.savedContents.single.questions.single.answer, '비흡연');
  });

  test('blocks an unanswered required submission', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(intakeFormProvider.future);

    expect(
      await container.read(intakeFormProvider.notifier).submitForm(),
      isFalse,
    );
    expect(repository.savedContents, isEmpty);
  });

  test('submits valid answers with submitted status', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(intakeFormProvider.future);
    final notifier = container.read(intakeFormProvider.notifier);
    notifier.updateAnswer('smoking', '현재 흡연');

    expect(await notifier.submitForm(), isTrue);
    expect(repository.savedContents.single.status, IntakeStatus.submitted);
  });

  test('keeps local input when saving fails', () async {
    final repository = _FakeRepository(shouldFail: true);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(intakeFormProvider.future);
    final notifier = container.read(intakeFormProvider.notifier);
    notifier.updateAnswer('smoking', '비흡연');

    expect(await notifier.saveDraft(), isFalse);
    expect(
      container.read(intakeFormProvider).value?.questions.single.answer,
      '비흡연',
    );
  });

  test('blocks a duplicate save while the first PUT is in progress', () async {
    final blocker = Completer<void>();
    final repository = _FakeRepository(saveBlocker: blocker);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(intakeFormProvider.future);
    final notifier = container.read(intakeFormProvider.notifier);
    notifier.updateAnswer('smoking', '비흡연');

    final firstSave = notifier.saveDraft();
    await Future<void>.delayed(Duration.zero);
    expect(await notifier.saveDraft(), isFalse);
    expect(repository.savedContents, hasLength(1));

    blocker.complete();
    expect(await firstSave, isTrue);
  });
}

ProviderContainer _container(IntakeRepository repository) {
  final container = ProviderContainer(
    overrides: [intakeRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(intakeFormProvider, (_, _) {});
  return container;
}

class _FakeRepository extends IntakeRepository {
  _FakeRepository({this.shouldFail = false, this.saveBlocker})
    : super(IntakeApi(ApiClient(dio: Dio())));

  final bool shouldFail;
  final Completer<void>? saveBlocker;
  final List<IntakeContent> savedContents = <IntakeContent>[];

  @override
  Future<IntakeForm> fetchMyIntake() async => _form;

  @override
  Future<IntakeForm> saveMyIntake(IntakeContent content) async {
    if (shouldFail) throw Exception('failed');
    savedContents.add(content);
    await saveBlocker?.future;
    return IntakeForm(
      id: _form.id,
      content: content,
      submittedAt: content.status == IntakeStatus.submitted
          ? DateTime(2026, 8, 5)
          : null,
      updatedAt: DateTime(2026, 8, 5),
    );
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
    ],
  ),
  submittedAt: null,
  updatedAt: DateTime(2026, 8, 5),
);
