class SymptomRecord {
  const SymptomRecord({
    required this.id,
    required this.patientName,
    required this.checkedAt,
    required this.symptoms,
    required this.riskLevel,
    required this.visibleToNurse,
    required this.nurseReviewed,
    required this.nurseReviewedAt,
  });

  final String id;
  final String? patientName;
  final DateTime checkedAt;
  final SymptomAnswers symptoms;
  final String riskLevel;
  final bool visibleToNurse;
  final bool nurseReviewed;
  final DateTime? nurseReviewedAt;

  DateTime get recordedAt => checkedAt;

  factory SymptomRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final patientName = json['patient_name'];
    final checkedAtValue = json['checked_at'];
    final symptomsValue = json['symptoms'];
    final riskLevel = json['risk_level'];
    final visibleToNurse = json['visible_to_nurse'];
    final nurseReviewed = json['nurse_reviewed'];
    final nurseReviewedAtValue = json['nurse_reviewed_at'];

    if (id is! String ||
        (patientName != null && patientName is! String) ||
        checkedAtValue is! String ||
        symptomsValue is! Map<String, dynamic> ||
        riskLevel is! String ||
        visibleToNurse is! bool ||
        nurseReviewed is! bool ||
        (nurseReviewedAtValue != null && nurseReviewedAtValue is! String)) {
      throw const FormatException('증상 기록 필드 형식이 올바르지 않습니다.');
    }

    final checkedAt = DateTime.tryParse(checkedAtValue);
    final nurseReviewedAt = nurseReviewedAtValue == null
        ? null
        : DateTime.tryParse(nurseReviewedAtValue);
    if (checkedAt == null ||
        (nurseReviewedAtValue != null && nurseReviewedAt == null)) {
      throw const FormatException('증상 기록 날짜 형식이 올바르지 않습니다.');
    }

    return SymptomRecord(
      id: id,
      patientName: patientName as String?,
      checkedAt: checkedAt,
      symptoms: SymptomAnswers.fromJson(symptomsValue),
      riskLevel: riskLevel,
      visibleToNurse: visibleToNurse,
      nurseReviewed: nurseReviewed,
      nurseReviewedAt: nurseReviewedAt,
    );
  }
}

class SymptomAnswers {
  const SymptomAnswers({
    required this.cough,
    required this.dyspnea,
    required this.hemoptysis,
    required this.chestPain,
    required this.fever,
    required this.weightLoss,
    required this.appetite,
    required this.fatigue,
  });

  final String cough;
  final String dyspnea;
  final String hemoptysis;
  final String chestPain;
  final String fever;
  final String weightLoss;
  final String appetite;
  final String fatigue;

  factory SymptomAnswers.fromJson(Map<String, dynamic> json) {
    final values = <String, dynamic>{
      'cough': json['cough'],
      'dyspnea': json['dyspnea'],
      'hemoptysis': json['hemoptysis'],
      'chest_pain': json['chest_pain'],
      'fever': json['fever'],
      'weight_loss': json['weight_loss'],
      'appetite': json['appetite'],
      'fatigue': json['fatigue'],
    };
    if (values.values.any((value) => value is! String)) {
      throw const FormatException('증상 응답 필드 형식이 올바르지 않습니다.');
    }

    return SymptomAnswers(
      cough: values['cough']! as String,
      dyspnea: values['dyspnea']! as String,
      hemoptysis: values['hemoptysis']! as String,
      chestPain: values['chest_pain']! as String,
      fever: values['fever']! as String,
      weightLoss: values['weight_loss']! as String,
      appetite: values['appetite']! as String,
      fatigue: values['fatigue']! as String,
    );
  }
}
