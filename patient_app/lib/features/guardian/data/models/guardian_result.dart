class GuardianResult {
  const GuardianResult({
    required this.finalSubtype,
    required this.genePredictions,
    required this.confirmedAt,
    required this.releasedAt,
  });

  factory GuardianResult.fromJson(Map<String, dynamic> json) {
    return GuardianResult(
      finalSubtype: _readNullableString(json, 'final_subtype'),
      genePredictions: _readGenePredictions(json),
      confirmedAt: _readNullableDateTime(json, 'confirmed_at'),
      releasedAt: _readNullableDateTime(json, 'released_at'),
    );
  }

  final String? finalSubtype;
  final List<GuardianGenePrediction> genePredictions;
  final DateTime? confirmedAt;
  final DateTime? releasedAt;

  static List<GuardianGenePrediction> _readGenePredictions(
    Map<String, dynamic> json,
  ) {
    final value = json['gene_predictions'];
    if (value is! List<dynamic>) {
      throw const FormatException('gene_predictions 필드는 배열이어야 합니다.');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('gene_predictions 항목은 객체여야 합니다.');
      }
      return GuardianGenePrediction.fromJson(item);
    }).toList(growable: false);
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('$key 필드는 문자열 또는 null이어야 합니다.');
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열 또는 null이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key 날짜 형식이 올바르지 않습니다.');
    return parsed;
  }
}

class GuardianGenePrediction {
  const GuardianGenePrediction({
    required this.geneName,
    required this.likelihood,
  });

  factory GuardianGenePrediction.fromJson(Map<String, dynamic> json) {
    final geneName = json['gene_name'];
    final likelihood = json['likelihood'];
    if (geneName is! String) {
      throw const FormatException('gene_name 필드는 문자열이어야 합니다.');
    }
    if (likelihood != null && likelihood is! num) {
      throw const FormatException('likelihood 필드는 숫자 또는 null이어야 합니다.');
    }
    return GuardianGenePrediction(
      geneName: geneName,
      likelihood: (likelihood as num?)?.toDouble(),
    );
  }

  final String geneName;
  final double? likelihood;
}
