import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/models/symptom_submit_request.dart';
import 'package:patient_app/features/symptom/data/symptom_api.dart';

void main() {
  group('SymptomApi.fetchMySymptomRecords', () {
    test('gets the exact patient list endpoint without a wrapper', () async {
      final client = _FakeApiClient(responseData: <dynamic>[]);
      final records = await SymptomApi(client).fetchMySymptomRecords();

      expect(client.lastPath, '/api/symptoms/checks/mine/');
      expect(records, isEmpty);
    });

    test('returns an array response unchanged', () async {
      final data = <dynamic>[
        <String, dynamic>{'id': 'record-id'},
      ];
      final records = await SymptomApi(
        _FakeApiClient(responseData: data),
      ).fetchMySymptomRecords();
      expect(records, same(data));
    });

    test('rejects a wrapped response', () async {
      final api = SymptomApi(
        _FakeApiClient(responseData: <String, dynamic>{'results': <dynamic>[]}),
      );
      await expectLater(api.fetchMySymptomRecords(), throwsFormatException);
    });
  });

  group('SymptomApi.submitSymptoms', () {
    test('posts the exact request body to the checks endpoint', () async {
      final client = _FakeApiClient(responseData: _recordJson);
      final api = SymptomApi(client);

      await api.submitSymptoms(_request);

      expect(client.lastPath, '/api/symptoms/checks/');
      expect(client.lastData, _request.toJson());
    });

    test(
      'returns a successful object response for repository parsing',
      () async {
        final api = SymptomApi(_FakeApiClient(responseData: _recordJson));

        expect(await api.submitSymptoms(_request), same(_recordJson));
      },
    );

    test('rejects a successful response that is not an object', () async {
      final api = SymptomApi(_FakeApiClient(responseData: 'unknown'));

      await expectLater(api.submitSymptoms(_request), throwsFormatException);
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
  memo: '개인 메모',
);

final _recordJson = <String, dynamic>{
  'id': 'record-id',
  'patient_name': null,
  'checked_at': '2026-08-06T09:00:00+09:00',
  'symptoms': <String, dynamic>{
    'cough': '없음',
    'dyspnea': '없음',
    'hemoptysis': '없음',
    'chest_pain': '없음',
    'fever': '없음',
    'weight_loss': '없음',
    'appetite': '평소와 같음',
    'fatigue': '없음',
  },
  'memo': '개인 메모',
  'risk_level': 'green',
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  String? lastPath;
  Object? lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    if (error != null) throw error!;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }

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
