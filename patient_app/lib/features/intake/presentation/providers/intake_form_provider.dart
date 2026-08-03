import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/intake_form.dart';
import '../../../../data/repositories/intake_form_repository.dart';
import '../../../../data/repositories/mock_intake_form_repository.dart';

final intakeFormRepositoryProvider =
    Provider<IntakeFormRepository>((ref) {
  return MockIntakeFormRepository();
});

final intakeFormProvider =
    AsyncNotifierProvider<IntakeFormNotifier, IntakeForm>(
  IntakeFormNotifier.new,
);

class IntakeFormNotifier extends AsyncNotifier<IntakeForm> {
  @override
  Future<IntakeForm> build() async {
    final repository = ref.read(
      intakeFormRepositoryProvider,
    );

    return repository.getIntakeForm();
  }

  Future<bool> saveAnswer({
    required String questionId,
    required IntakeAnswer answer,
  }) async {
    final repository = ref.read(
      intakeFormRepositoryProvider,
    );

    try {
      final updatedForm = await repository.saveAnswer(
        questionId: questionId,
        answer: answer,
      );

      state = AsyncData(updatedForm);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> submitForm() async {
    final repository = ref.read(
      intakeFormRepositoryProvider,
    );

    try {
      final completedForm =
          await repository.submitIntakeForm();

      state = AsyncData(completedForm);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> reloadForm() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        intakeFormRepositoryProvider,
      );

      return repository.getIntakeForm();
    });
  }
}