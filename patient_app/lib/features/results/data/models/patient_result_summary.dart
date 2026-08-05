class PatientResultSummary {
  const PatientResultSummary({
    this.id,
    this.specimenId,
    this.finalSubtype,
    this.finalNote,
    this.confirmedAt,
    this.releasedAt,
  });

  factory PatientResultSummary.fromJson(Map<String, dynamic> json) {
    return PatientResultSummary(
      id: _readNullableString(json, 'id'),
      specimenId: _readNullableString(json, 'specimen_id'),
      finalSubtype: _readNullableString(json, 'final_subtype'),
      finalNote: _readNullableString(json, 'final_note'),
      confirmedAt: _readNullableDateTime(json, 'confirmed_at'),
      releasedAt: _readNullableDateTime(json, 'released_at'),
    );
  }

  final String? id;
  final String? specimenId;
  final String? finalSubtype;
  final String? finalNote;
  final DateTime? confirmedAt;
  final DateTime? releasedAt;

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열이어야 합니다.');
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key 필드의 날짜 형식이 올바르지 않습니다.');
    }

    return parsed;
  }
}
