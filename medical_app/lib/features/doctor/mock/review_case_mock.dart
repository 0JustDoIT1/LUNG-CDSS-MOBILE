import '../models/review_case.dart';

/// 화면 확인용 mock 데이터.
/// 나중에 실제 API 붙이면 이 함수를 지우고 repository에서 데이터를 받아오면 됨.
List<ReviewCase> mockReviewCases() {
  final now = DateTime.now();
  return [
    ReviewCase(
      id: 'C-1001',
      patientName: '김O수',
      type: CaseType.luad,
      confidence: 0.82,
      aiSummary: 'LUAD(폐선암) 의심',
      status: CaseStatus.pending,
      submittedAt: now.subtract(const Duration(hours: 2)),
      isFavorite: true,
      genePredictions: const {'TP53': 0.74, 'KEAP1': 0.31, 'KRAS': 0.12},
      aiOpinion: 'LUAD 소견에 부합하는 소견입니다. 종양표지자 및 조직학적 '
          '특징을 고려할 때 추가 유전자검사(TP53 변이 확인)를 권장합니다.',
    ),
    ReviewCase(
      id: 'C-1002',
      patientName: '이O진',
      type: CaseType.lusc,
      confidence: 0.67,
      aiSummary: 'LUSC(편평상피세포암) 의심',
      status: CaseStatus.pending,
      submittedAt: now.subtract(const Duration(hours: 5)),
      genePredictions: const {'TP53': 0.58, 'KEAP1': 0.45, 'KRAS': 0.09},
      aiOpinion: 'LUSC 가능성이 있으나 신뢰도가 낮아 병리과 재확인이 '
          '필요합니다. 조직 재염색을 고려하십시오.',
    ),
    ReviewCase(
      id: 'C-1003',
      patientName: '최O수',
      type: CaseType.luad,
      confidence: 0.68,
      aiSummary: 'LUAD(폐선암) 의심',
      status: CaseStatus.pending,
      submittedAt: now.subtract(const Duration(hours: 1)),
      genePredictions: const {'TP53': 0.22, 'KEAP1': 0.15, 'KRAS': 0.61},
      aiOpinion: 'KRAS 변이 확률이 높게 나타나 표적치료 적합성 검토가 '
          '필요합니다.',
    ),
    ReviewCase(
      id: 'C-0998',
      patientName: '박O훈',
      type: CaseType.luad,
      confidence: 0.91,
      aiSummary: '정상 소견, 추적관찰 권고',
      status: CaseStatus.approved,
      submittedAt: now.subtract(const Duration(days: 1)),
      genePredictions: const {'TP53': 0.08, 'KEAP1': 0.05, 'KRAS': 0.04},
      aiOpinion: '정상 소견으로 판단됨. 6개월 후 추적관찰을 권장합니다.',
    ),
  ];
}

/// 같은 환자의 이전 케이스 mock 데이터 (비교뷰용).
/// 실제 연결 시 patientId 기준으로 과거 케이스 조회 API로 교체.
ReviewCase? mockPreviousCase(ReviewCase current) {
  return ReviewCase(
    id: '${current.id}-prev',
    patientName: current.patientName,
    type: current.type,
    confidence: (current.confidence - 0.15).clamp(0.0, 1.0),
    aiSummary: '${current.aiSummary} (이전 검사)',
    status: CaseStatus.approved,
    submittedAt: current.submittedAt.subtract(const Duration(days: 90)),
    genePredictions: current.genePredictions.map(
      (key, value) => MapEntry(key, (value - 0.1).clamp(0.0, 1.0)),
    ),
    aiOpinion: '3개월 전 검사 소견. 당시 추적관찰 권고됨.',
  );
}