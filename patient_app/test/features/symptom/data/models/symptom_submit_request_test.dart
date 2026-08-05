import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/data/models/symptom_submit_request.dart';

void main() {
  group('SymptomSubmitRequest', () {
    test('serializes valid values with server key names', () {
      final json = _request().toJson();

      expect(json, <String, dynamic>{
        'cough': '약간',
        'dyspnea': '활동시만',
        'hemoptysis': '소량',
        'chest_pain': '심함',
        'fever': '37.5~38',
        'weight_loss': '있음',
        'appetite': '감소',
        'fatigue': '약간',
      });
      expect(json, isNot(contains('chestPain')));
      expect(json, isNot(contains('weightLoss')));
      expect(json, isNot(contains('memo')));
    });

    test('accepts every documented value for each field', () {
      for (final value in SymptomSubmitRequest.coughValues) {
        expect(() => _request(cough: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.dyspneaValues) {
        expect(() => _request(dyspnea: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.hemoptysisValues) {
        expect(() => _request(hemoptysis: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.chestPainValues) {
        expect(() => _request(chestPain: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.feverValues) {
        expect(() => _request(fever: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.weightLossValues) {
        expect(() => _request(weightLoss: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.appetiteValues) {
        expect(() => _request(appetite: value), returnsNormally);
      }
      for (final value in SymptomSubmitRequest.fatigueValues) {
        expect(() => _request(fatigue: value), returnsNormally);
      }
    });

    test('rejects an undocumented value', () {
      expect(() => _request(cough: 'medium'), throwsArgumentError);
    });
  });
}

SymptomSubmitRequest _request({
  String cough = '약간',
  String dyspnea = '활동시만',
  String hemoptysis = '소량',
  String chestPain = '심함',
  String fever = '37.5~38',
  String weightLoss = '있음',
  String appetite = '감소',
  String fatigue = '약간',
}) {
  return SymptomSubmitRequest(
    cough: cough,
    dyspnea: dyspnea,
    hemoptysis: hemoptysis,
    chestPain: chestPain,
    fever: fever,
    weightLoss: weightLoss,
    appetite: appetite,
    fatigue: fatigue,
  );
}
