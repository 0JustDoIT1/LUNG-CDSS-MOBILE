import '../../../core/utils/datetime_utils.dart';

/// 의사가 검토해야 하는 케이스 하나.
/// 실제 API(GET /api/cases/, GET /api/cases/{id}/) 응답 구조에 맞춘 모델.
/// 주의: prediction_label/luad_probability/lusc_probability/heatmap_url/
/// gene_predictions/treatment_note는 목록(GET /api/cases/)에선 최상위에 있지만,
/// 상세(GET /api/cases/{id}/)에선 latest_ai_result 객체 안에 중첩되어 있음
/// — fromJson이 둘 다 처리함.
/// slideThumbnailUrl/genePredictions/treatmentNote는 상세조회에만 있어서
/// 목록으로 만든 ReviewCase에는 비어있음.
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
  final String? slideThumbnailUrl; // 원본 슬라이드 이미지
  final String? heatmapUrl; // AI 히트맵 이미지
  final List<GenePrediction> genePredictions;
  final String? treatmentNote; // AI 소견 텍스트
  final String? finalSubtype; // 의사가 확정한 최종 아형 ('LUAD' | 'LUSC') — confirmed 상태일 때만 존재
  final String? finalNote; // 의사가 확정한 최종 소견

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
    this.slideThumbnailUrl,
    this.heatmapUrl,
    this.genePredictions = const [],
    this.treatmentNote,
    this.finalSubtype,
    this.finalNote,
  });

  /// confidence 70% 미만이면 긴급 케이스.
  bool get isUrgent => confidence < 0.7;

  factory ReviewCase.fromJson(Map<String, dynamic> json) {
    // 상세조회는 AI 예측값이 latest_ai_result 안에 중첩됨. 목록은 최상위.
    final aiResult = json['latest_ai_result'] as Map<String, dynamic>?;
    final source = aiResult ?? json;

    final label = source['prediction_label'] as String? ?? 'LUAD';
    final type = label == 'LUSC' ? CaseType.lusc : CaseType.luad;
    final luad = (source['luad_probability'] as num?)?.toDouble() ?? 0;
    final lusc = (source['lusc_probability'] as num?)?.toDouble() ?? 0;
    final genePredictions = (source['gene_predictions'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(GenePrediction.fromJson)
            .toList() ??
        const [];

    return ReviewCase(
      id: json['id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      specimenId: json['specimen_id'] as String? ?? '',
      type: type,
      confidence: type == CaseType.luad ? luad : lusc,
      status: json['status'] == 'confirmed' ? CaseStatus.confirmed : CaseStatus.pending,
      uploadedAt: parseServerDateTime(json['uploaded_at'] as String),
      completedAt: json['completed_at'] != null
          ? parseServerDateTime(json['completed_at'] as String)
          : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
      slideThumbnailUrl: json['slide_thumbnail_url'] as String?,
      heatmapUrl: source['heatmap_url'] as String?,
      genePredictions: genePredictions,
      treatmentNote: source['treatment_note'] as String?,
      finalSubtype: json['final_subtype'] as String?,
      finalNote: json['final_note'] as String?,
    );
  }
}

/// latest_ai_result.gene_predictions 배열 항목 하나 (유전자명 + 변이 확률).
class GenePrediction {
  final String gene;
  final double probability;

  GenePrediction({required this.gene, required this.probability});

  factory GenePrediction.fromJson(Map<String, dynamic> json) {
    return GenePrediction(
      gene: json['gene_name'] as String? ?? '',
      probability: (json['likelihood'] as num?)?.toDouble() ?? 0,
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