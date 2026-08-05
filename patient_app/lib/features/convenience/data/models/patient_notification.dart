class PatientNotification {
  const PatientNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.isRead,
    required this.createdAt,
  });

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    return PatientNotification(
      id: _readString(json, 'id'),
      category: _readString(json, 'category'),
      title: _readString(json, 'title'),
      body: _readString(json, 'body'),
      deepLink: _readNullableString(json, 'deep_link'),
      isRead: _readBool(json, 'is_read'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }

  final String id;
  final String category;
  final String title;
  final String body;
  final String? deepLink;
  final bool isRead;
  final DateTime createdAt;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is String) {
      return value;
    }

    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    throw FormatException('$key 필드는 문자열 또는 null이어야 합니다.');
  }

  static bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is bool) {
      return value;
    }

    throw FormatException('$key 필드는 boolean이어야 합니다.');
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

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
