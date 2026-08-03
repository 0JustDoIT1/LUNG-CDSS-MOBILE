import '../models/intake_form.dart';

abstract class IntakeFormRepository {
  Future<IntakeForm> getIntakeForm();

  Future<IntakeForm> saveAnswer({
    required String questionId,
    required IntakeAnswer answer,
  });

  Future<IntakeForm> submitIntakeForm();
}