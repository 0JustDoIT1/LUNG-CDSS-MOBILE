import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/intake/data/intake_api.dart';
import 'package:patient_app/features/intake/data/intake_repository.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';

void main() {
  test('parses GET and PUT responses as IntakeForm', () async {
    final repository = IntakeRepository(_FakeIntakeApi());
    expect((await repository.fetchMyIntake()).id, 'intake-id');
    expect(
      (await repository.saveMyIntake(
        const IntakeContent(
          status: IntakeStatus.draft,
          questions: <IntakeQuestion>[],
        ),
      )).content.status,
      IntakeStatus.draft,
    );
  });

  test('preserves ApiException', () async {
    const exception = ApiException(message: 'forbidden', statusCode: 403);
    final repository = IntakeRepository(_FakeIntakeApi(error: exception));
    await expectLater(repository.fetchMyIntake(), throwsA(same(exception)));
  });
}

class _FakeIntakeApi extends IntakeApi {
  _FakeIntakeApi({this.error}) : super(ApiClient(dio: Dio()));

  final Object? error;

  @override
  Future<Map<String, dynamic>> fetchMyIntake() async {
    if (error != null) throw error!;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> saveMyIntake(IntakeContent content) async {
    if (error != null) throw error!;
    return _response;
  }
}

final _response = <String, dynamic>{
  'id': 'intake-id',
  'content': <String, dynamic>{'status': 'draft', 'questions': <dynamic>[]},
  'submitted_at': null,
  'updated_at': '2026-08-05T16:10:00+09:00',
};
