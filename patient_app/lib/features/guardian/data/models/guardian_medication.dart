class GuardianMedication {
  const GuardianMedication({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.scheduledTime,
    required this.taken,
    required this.takenAt,
  });

  factory GuardianMedication.fromJson(Map<String, dynamic> json) {
    return GuardianMedication(
      id: _readString(json, 'id'),
      drugName: _readString(json, 'drug_name'),
      dosage: _readString(json, 'dosage'),
      scheduledTime: _readDateTime(json, 'scheduled_time'),
      taken: _readBool(json, 'taken'),
      takenAt: _readNullableDateTime(json, 'taken_at'),
    );
  }

  final String id;
  final String drugName;
  final String dosage;
  final DateTime scheduledTime;
  final bool taken;
  final DateTime? takenAt;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('$key 필드는 boolean이어야 합니다.');
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key 날짜 형식이 올바르지 않습니다.');
    return parsed;
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
