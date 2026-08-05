import 'models/symptom_submit_request.dart';
import 'symptom_api.dart';

class SymptomRepository {
  SymptomRepository(this._symptomApi);

  final SymptomApi _symptomApi;

  Future<void> submitSymptoms(SymptomSubmitRequest request) {
    return _symptomApi.submitSymptoms(request);
  }
}
