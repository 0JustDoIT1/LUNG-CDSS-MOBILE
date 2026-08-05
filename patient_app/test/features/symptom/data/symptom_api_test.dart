import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/models/symptom_submit_request.dart';
import 'package:patient_app/features/symptom/data/symptom_api.dart';

void main() {
  group('SymptomApi.submitSymptoms', () {
    test('posts the exact request body to the checks endpoint', () async {
      final client = _FakeApiClient(
        responseData: <String, dynamic>{
          'unmodeled': <String, dynamic>{'nested': true},
        },
      );
      final api = SymptomApi(client);

      await api.submitSymptoms(_request);

      expect(client.lastPath, '/api/symptoms/checks/');
      expect(client.lastData, _request.toJson());
    });

    test('does not parse a successful response body', () async {
      final api = SymptomApi(_FakeApiClient(responseData: 'unknown'));

      await expectLater(api.submitSymptoms(_request), completes);
    });

    test('preserves an ApiException from ApiClient', () async {
      const exception = ApiException(message: 'failed', statusCode: 403);
      final api = SymptomApi(_FakeApiClient(error: exception));

      await expectLater(api.submitSymptoms(_request), throwsA(same(exception)));
    });
  });
}

final _request = SymptomSubmitRequest(
  cough: '없음',
  dyspnea: '없음',
  hemoptysis: '없음',
  chestPain: '없음',
  fever: '없음',
  weightLoss: '없음',
  appetite: '평소와 같음',
  fatigue: '없음',
);

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  String? lastPath;
  Object? lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
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
