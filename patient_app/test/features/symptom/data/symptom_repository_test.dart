import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/models/symptom_submit_request.dart';
import 'package:patient_app/features/symptom/data/symptom_api.dart';
import 'package:patient_app/features/symptom/data/symptom_repository.dart';

void main() {
  group('SymptomRepository.submitSymptoms', () {
    test('completes after the API succeeds', () async {
      final api = _FakeSymptomApi();
      final repository = SymptomRepository(api);

      await repository.submitSymptoms(_request);

      expect(api.receivedRequest, same(_request));
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
  _FakeSymptomApi({this.error}) : super(ApiClient(dio: Dio()));

  final Object? error;
  SymptomSubmitRequest? receivedRequest;

  @override
  Future<void> submitSymptoms(SymptomSubmitRequest request) async {
    if (error != null) {
      throw error!;
    }
    receivedRequest = request;
  }
}
