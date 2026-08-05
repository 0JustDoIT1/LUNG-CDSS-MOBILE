/// 의사가 검토해야 하는 케이스 하나.
/// 실제 API(GET /api/cases/, GET /api/cases/{id}/) 응답 구조에 맞춘 모델.
/// TODO: gene predictions / AI소견 텍스트는 실제 CaseDetail 응답 구조 확인 후 추가.
class ReviewCase {
  final String id;
  final String patientName;
  final String specimenId;
  final CaseType type; // prediction_label 기준
  final double confidence; // type에 해당하는 확률(luad_probability 또는 lusc_probability)
  final CaseStatus status;
  final DateTime uploadedAt;
  final DateTime? completedAt;
  bool isFavorite;

  ReviewCase({
    required this.id,
    required this.patientName,
    required this.specimenId,
    required this.type,
    required this.confidence,
    required this.status,
    required this.uploadedAt,
    this.completedAt,
    this.isFavorite = false,
  });

  /// confidence 70% 미만이면 긴급 케이스.
  bool get isUrgent => confidence < 0.7;

  factory ReviewCase.fromJson(Map<String, dynamic> json) {
    final label = json['prediction_label'] as String? ?? 'LUAD';
    final type = label == 'LUSC' ? CaseType.lusc : CaseType.luad;
    final luad = (json['luad_probability'] as num?)?.toDouble() ?? 0;
    final lusc = (json['lusc_probability'] as num?)?.toDouble() ?? 0;

    return ReviewCase(
      id: json['id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      specimenId: json['specimen_id'] as String? ?? '',
      type: type,
      confidence: type == CaseType.luad ? luad : lusc,
      status: json['status'] == 'confirmed' ? CaseStatus.confirmed : CaseStatus.pending,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
}

enum CaseType {
  luad, // 폐선암
  lusc; // 편평상피세포암

  String get label => switch (this) {
        CaseType.luad => 'LUAD',
        CaseType.lusc => 'LUSC',
      };
}

/// 서버 status는 uploaded/processing/pending_review/confirmed/failed 5단계지만,
/// 의사 앱에는 검토가 필요한 pending_review와 처리 끝난 confirmed 2가지만 노출.
/// (uploaded/processing/failed는 병리사 쪽 단계라 의사 목록에서 애초에 제외)
enum CaseStatus {
  pending, // pending_review
  confirmed; // confirmed (승인/반려 둘 다 이 상태로 귀결됨 — 서버는 둘을 구분 안 함)

  String get label => switch (this) {
        CaseStatus.pending => '검토대기',
        CaseStatus.confirmed => '확정됨',
      };
}