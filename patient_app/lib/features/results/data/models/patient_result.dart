class PatientResult {
  const PatientResult({
    required this.caseId,
    required this.specimenId,
    required this.finalSubtype,
    required this.finalNote,
    required this.luadProbability,
    required this.luscProbability,
    required this.genePredictions,
    required this.isReleased,
    required this.confirmedAt,
    required this.releasedAt,
  });

  factory PatientResult.fromJson(Map<String, dynamic> json) {
    return PatientResult(
      caseId: _requiredString(json, 'case_id'),
      specimenId: _requiredString(json, 'specimen_id'),
      finalSubtype: _nullableString(json, 'final_subtype'),
      finalNote: _nullableString(json, 'final_note'),
      luadProbability: _nullableProbability(json, 'luad_probability'),
      luscProbability: _nullableProbability(json, 'lusc_probability'),
      genePredictions: _genePredictions(json['gene_predictions']),
      isReleased: _requiredBool(json, 'is_released'),
      confirmedAt: _nullableDateTime(json, 'confirmed_at'),
      releasedAt: _nullableDateTime(json, 'released_at'),
    );
  }

  final String caseId;
  final String specimenId;
  final String? finalSubtype;
  final String? finalNote;
  final double? luadProbability;
  final double? luscProbability;
  final List<GenePrediction> genePredictions;
  final bool isReleased;
  final DateTime? confirmedAt;
  final DateTime? releasedAt;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('$key 필드는 문자열 또는 null이어야 합니다.');
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('$key 필드는 bool이어야 합니다.');
  }

  static double? _nullableProbability(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num) {
      throw FormatException('$key 필드는 숫자 또는 null이어야 합니다.');
    }
    final probability = value.toDouble();
    if (probability < 0 || probability > 1) {
      throw FormatException('$key 필드는 0과 1 사이여야 합니다.');
    }
    return probability;
  }

  static DateTime? _nullableDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열 또는 null이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key 날짜 형식이 올바르지 않습니다.');
    return parsed;
  }

  static List<GenePrediction> _genePredictions(Object? value) {
    if (value == null) return const [];
    if (value is! List<dynamic>) {
      throw const FormatException('gene_predictions 필드는 배열이어야 합니다.');
    }
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('gene_predictions 항목은 객체여야 합니다.');
          }
          return GenePrediction.fromJson(item);
        })
        .toList(growable: false);
  }
}

class GenePrediction {
  const GenePrediction({required this.geneName, required this.likelihood});

  factory GenePrediction.fromJson(Map<String, dynamic> json) {
    return GenePrediction(
      geneName: PatientResult._requiredString(json, 'gene_name'),
      likelihood: PatientResult._nullableProbability(json, 'likelihood'),
    );
  }

  final String geneName;
  final double? likelihood;
}

String patientResultDetailLabel(String? subtype) {
  if (subtype == null || subtype.trim().isEmpty) {
    return '검사 결과를 확인 중입니다.';
  }
  switch (subtype.toUpperCase()) {
    case 'LUAD':
      return '폐선암(LUAD)으로 확인되었습니다.';
    case 'LUSC':
      return '편평상피세포암(LUSC)으로 확인되었습니다.';
    default:
      return '확정된 검사 결과를 확인해 주세요.';
  }
}

String patientResultListLabel(String? subtype) {
  if (subtype == null || subtype.trim().isEmpty) return '결과 확인 중';
  switch (subtype.toUpperCase()) {
    case 'LUAD':
      return '폐선암';
    case 'LUSC':
      return '편평상피세포암';
    default:
      return '확정 결과 확인 필요';
  }
}
