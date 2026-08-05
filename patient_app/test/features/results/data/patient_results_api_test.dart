import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/results/data/patient_results_api.dart';

void main() {
  group('PatientResultsApi', () {
    test('gets the patient results list endpoint', () async {
      final client = _FakeApiClient(responseData: <dynamic>[]);
      final api = PatientResultsApi(apiClient: client);

      await api.getMyResults();

      expect(client.lastPath, '/api/cases/my-results/');
    });

    test('gets the patient-only detail endpoint with caseId', () async {
      final client = _FakeApiClient(responseData: _validResult);
      final api = PatientResultsApi(apiClient: client);

      await api.getMyResultDetail('case-uuid');

      expect(client.lastPath, '/api/cases/my-results/case-uuid/');
    });

    test('blocks an empty caseId before a request', () async {
      final client = _FakeApiClient(responseData: _validResult);
      final api = PatientResultsApi(apiClient: client);

      await expectLater(api.getMyResultDetail('  '), throwsArgumentError);
      expect(client.callCount, 0);
    });

    test('preserves an ApiException', () async {
      const exception = ApiException(message: 'forbidden', statusCode: 403);
      final api = PatientResultsApi(
        apiClient: _FakeApiClient(error: exception),
      );

      await expectLater(api.getMyResults(), throwsA(same(exception)));
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

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  String? lastPath;
  int callCount = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    callCount++;
    if (error != null) throw error!;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
