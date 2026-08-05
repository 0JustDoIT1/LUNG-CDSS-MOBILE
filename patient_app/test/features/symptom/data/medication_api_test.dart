import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/medication_api.dart';

void main() {
  group('MedicationApi.markAsTaken', () {
    test('posts to the taken endpoint without a request body', () async {
      final apiClient = _FakeApiClient(responseData: _validResponse);
      final api = MedicationApi(apiClient);

      await api.markAsTaken('medication-log-uuid');

      expect(apiClient.postCallCount, 1);
      expect(
        apiClient.lastPath,
        '/api/medications/logs/medication-log-uuid/taken/',
      );
      expect(apiClient.lastData, isNull);
    });

    test('rejects an empty log id before making a request', () async {
      final apiClient = _FakeApiClient(responseData: _validResponse);
      final api = MedicationApi(apiClient);

      await expectLater(api.markAsTaken('   '), throwsArgumentError);

      expect(apiClient.postCallCount, 0);
    });

    test('rejects a response that is not an object', () async {
      final api = MedicationApi(_FakeApiClient(responseData: <dynamic>[]));

      await expectLater(
        api.markAsTaken('medication-log-uuid'),
        throwsFormatException,
      );
    });

    test('preserves an ApiException from ApiClient', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final api = MedicationApi(_FakeApiClient(error: apiException));

      await expectLater(
        api.markAsTaken('medication-log-uuid'),
        throwsA(same(apiException)),
      );
    });
  });
}

const _validResponse = <String, dynamic>{
  'id': 'medication-log-uuid',
  'drug_name': 'Medication',
  'dosage': 'One tablet',
  'scheduled_time': '2026-08-05T09:00:00+09:00',
  'taken': true,
  'taken_at': '2026-08-05T09:05:00+09:00',
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  int postCallCount = 0;
  String? lastPath;
  Object? lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postCallCount += 1;
    lastPath = path;
    lastData = data;

    if (error != null) {
      throw error!;
    }

    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
