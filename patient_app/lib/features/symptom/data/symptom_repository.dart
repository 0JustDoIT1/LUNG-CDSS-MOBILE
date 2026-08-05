import 'models/symptom_record.dart';
import 'models/symptom_submit_request.dart';
import 'symptom_api.dart';

class SymptomRepository {
  SymptomRepository(this._symptomApi);

  final SymptomApi _symptomApi;

  Future<List<SymptomRecord>> fetchMySymptomRecords() async {
    final records = await _symptomApi.fetchMySymptomRecords();
    return records
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('증상 기록 목록의 각 항목은 객체여야 합니다.');
          }
          return SymptomRecord.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> submitSymptoms(SymptomSubmitRequest request) {
    return _symptomApi.submitSymptoms(request);
  }
}
