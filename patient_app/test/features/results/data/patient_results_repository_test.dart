import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/results/data/patient_results_api.dart';
import 'package:patient_app/features/results/data/patient_results_repository.dart';

void main() {
  group('PatientResultsRepository.parseResults', () {
    test('rejects an array item that is not an object', () {
      expect(
        () => PatientResultsRepository.parseResults(<dynamic>['invalid']),
        throwsFormatException,
      );
    });

    test('parses an empty array', () {
      final results = PatientResultsRepository.parseResults(<dynamic>[]);

      expect(results, isEmpty);
    });
  });

  group('PatientResultsRepository detail', () {
    test('parses a detail object', () async {
      final repository = PatientResultsRepository(
        patientResultsApi: _FakePatientResultsApi(detail: _validResult),
      );

      final result = await repository.fetchMyResultDetail('case-uuid');

      expect(result.caseId, 'case-uuid');
      expect(result.specimenId, 'SPEC-001');
    });

    test('preserves an ApiException', () async {
      const exception = ApiException(message: 'not found', statusCode: 404);
      final repository = PatientResultsRepository(
        patientResultsApi: _FakePatientResultsApi(error: exception),
      );

      await expectLater(
        repository.fetchMyResultDetail('case-uuid'),
        throwsA(same(exception)),
      );
    });
  });
}

final Map<String, dynamic> _validResult = {
  'case_id': 'case-uuid',
  'specimen_id': 'SPEC-001',
  'final_subtype': 'LUAD',
  'final_note': null,
  'luad_probability': 0.81,
  'lusc_probability': 0.19,
  'gene_predictions': <dynamic>[],
  'is_released': true,
  'confirmed_at': null,
  'released_at': null,
};

class _FakePatientResultsApi extends PatientResultsApi {
  _FakePatientResultsApi({this.detail, this.error})
    : super(apiClient: ApiClient(dio: Dio()));

  final Map<String, dynamic>? detail;
  final Object? error;

  @override
  Future<Map<String, dynamic>> getMyResultDetail(String caseId) async {
    if (error != null) throw error!;
    return detail!;
  }
}
