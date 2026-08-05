class SymptomSubmitRequest {
  SymptomSubmitRequest({
    required this.cough,
    required this.dyspnea,
    required this.hemoptysis,
    required this.chestPain,
    required this.fever,
    required this.weightLoss,
    required this.appetite,
    required this.fatigue,
  }) {
    _validate(cough, coughValues, 'cough');
    _validate(dyspnea, dyspneaValues, 'dyspnea');
    _validate(hemoptysis, hemoptysisValues, 'hemoptysis');
    _validate(chestPain, chestPainValues, 'chestPain');
    _validate(fever, feverValues, 'fever');
    _validate(weightLoss, weightLossValues, 'weightLoss');
    _validate(appetite, appetiteValues, 'appetite');
    _validate(fatigue, fatigueValues, 'fatigue');
  }

  static const coughValues = <String>{'없음', '약간', '심함'};
  static const dyspneaValues = <String>{'없음', '활동시만', '안정시에도'};
  static const hemoptysisValues = <String>{'없음', '소량', '다량'};
  static const chestPainValues = <String>{'없음', '약간', '심함'};
  static const feverValues = <String>{'없음', '37.5~38', '38이상'};
  static const weightLossValues = <String>{'없음', '있음'};
  static const appetiteValues = <String>{'평소와 같음', '감소'};
  static const fatigueValues = <String>{'없음', '약간', '심함'};

  final String cough;
  final String dyspnea;
  final String hemoptysis;
  final String chestPain;
  final String fever;
  final String weightLoss;
  final String appetite;
  final String fatigue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cough': cough,
      'dyspnea': dyspnea,
      'hemoptysis': hemoptysis,
      'chest_pain': chestPain,
      'fever': fever,
      'weight_loss': weightLoss,
      'appetite': appetite,
      'fatigue': fatigue,
    };
  }

  static void _validate(String value, Set<String> allowed, String field) {
    if (!allowed.contains(value)) {
      throw ArgumentError.value(value, field, '허용되지 않은 증상 값입니다.');
    }
  }
}
