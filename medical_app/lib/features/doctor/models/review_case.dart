/// 의사가 검토해야 하는 케이스 하나를 나타내는 모델.
///
/// 지금은 API가 없어서 mock 데이터로만 채운다.
/// 실제 연결 시 이 클래스에 fromJson()만 추가하면
/// AIAnalysisResult / GenePrediction API 응답으로 바로 교체 가능.
class ReviewCase {
  final String id;
  final String patientName;
  final CaseType type; // LUAD / LUSC
  final double confidence; // 0.0 ~ 1.0, AIAnalysisResult 확률
  final String aiSummary;
  final CaseStatus status;
  final DateTime submittedAt;
  bool isFavorite; // CaseFavorite 연동 지점 — 토글 가능하도록 final 제거
  final Map<String, double> genePredictions; // GenePrediction: TP53/KEAP1/KRAS 등
  final String aiOpinion; // AIAnalysisResult.treatment_note (MedGemma 초안)

  ReviewCase({
    required this.id,
    required this.patientName,
    required this.type,
    required this.confidence,
    required this.aiSummary,
    required this.status,
    required this.submittedAt,
    this.isFavorite = false,
    this.genePredictions = const {},
    this.aiOpinion = '',
  });

  /// confidence 70% 미만이면 긴급 케이스.
  bool get isUrgent => confidence < 0.7;
}

enum CaseType {
  luad, // 폐선암
  lusc; // 편평상피세포암

  String get label => switch (this) {
        CaseType.luad => 'LUAD',
        CaseType.lusc => 'LUSC',
      };
}

enum CaseStatus {
  pending, // 검토대기
  approved, // 승인
  rejected; // 반려

  String get label => switch (this) {
        CaseStatus.pending => '검토대기',
        CaseStatus.approved => '승인',
        CaseStatus.rejected => '반려',
      };
}