class SymptomRecord {
  const SymptomRecord({
    required this.id,
    required this.recordedAt,
    required this.symptoms,
    required this.overallSeverity,
    required this.memo,
  });

  final String id;
  final DateTime recordedAt;
  final List<SymptomItem> symptoms;
  final int overallSeverity;
  final String memo;

  bool get hasSymptoms => symptoms.isNotEmpty;
}

class SymptomItem {
  const SymptomItem({
    required this.name,
    required this.severity,
  });

  final String name;

  /// 0: 없음, 1: 경미, 2: 보통, 3: 심함
  final int severity;
}