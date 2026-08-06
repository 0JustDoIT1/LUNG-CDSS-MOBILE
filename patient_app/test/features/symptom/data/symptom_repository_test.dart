import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/models/symptom_submit_request.dart';
import 'package:patient_app/features/symptom/data/symptom_api.dart';
import 'package:patient_app/features/symptom/data/symptom_repository.dart';

void main() {
  group('SymptomRepository.fetchMySymptomRecords', () {
    test('parses records and preserves an empty array', () async {
      final repository = SymptomRepository(
        _FakeSymptomApi(records: <dynamic>[]),
      );
      expect(await repository.fetchMySymptomRecords(), isEmpty);
    });

    test('rejects a non-object array item', () async {
      final repository = SymptomRepository(
        _FakeSymptomApi(records: <dynamic>['invalid']),
      );
      await expectLater(
        repository.fetchMySymptomRecords(),
        throwsFormatException,
      );
    });

    test('preserves an ApiException', () async {
      const exception = ApiException(message: 'failed', statusCode: 403);
      final repository = SymptomRepository(
        _FakeSymptomApi(fetchError: exception),
      );
      await expectLater(
        repository.fetchMySymptomRecords(),
        throwsA(same(exception)),
      );
    });
  });

  group('SymptomRepository.submitSymptoms', () {
    test('parses the created record after the API succeeds', () async {
      final api = _FakeSymptomApi();
      final repository = SymptomRepository(api);

      final record = await repository.submitSymptoms(_request);

      expect(api.receivedRequest, same(_request));
      expect(record.id, 'created-record');
      expect(record.memo, '개인 메모');
    });

    test('preserves an ApiException', () async {
      const exception = ApiException(message: 'failed', statusCode: 400);
      final repository = SymptomRepository(_FakeSymptomApi(error: exception));

      await expectLater(
        repository.submitSymptoms(_request),
        throwsA(same(exception)),
      );
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

class _FakeSymptomApi extends SymptomApi {
  _FakeSymptomApi({
    this.error,
    this.records = const <dynamic>[],
    this.fetchError,
  }) : super(ApiClient(dio: Dio()));

  final Object? error;
  final List<dynamic> records;
  final Object? fetchError;
  SymptomSubmitRequest? receivedRequest;

  @override
  Future<List<dynamic>> fetchMySymptomRecords() async {
    if (fetchError != null) throw fetchError!;
    return records;
  }

  @override
  Future<Map<String, dynamic>> submitSymptoms(
    SymptomSubmitRequest request,
  ) async {
    if (error != null) {
      throw error!;
    }
    receivedRequest = request;
    return _createdRecordJson;
  }
}

final _createdRecordJson = <String, dynamic>{
  'id': 'created-record',
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
