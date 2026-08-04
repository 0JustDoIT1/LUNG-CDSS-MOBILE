import '../models/case_review_log.dart';

/// 화면 확인용 mock 데이터. 특정 caseId의 검토이력을 시간순으로 반환.
List<CaseReviewLog> mockReviewLogs(String caseId) {
  final now = DateTime.now();
  return [
    CaseReviewLog(
      caseId: caseId,
      action: ReviewAction.edited,
      reviewerName: '김의사',
      timestamp: now.subtract(const Duration(days: 3, hours: 2)),
      opinionSnapshot: 'LUSC 가능성 우선 검토 필요. 조직 재염색 권고.',
    ),
    CaseReviewLog(
      caseId: caseId,
      action: ReviewAction.confirmed,
      reviewerName: '박의사',
      timestamp: now.subtract(const Duration(days: 1, hours: 5)),
      opinionSnapshot: 'AI 소견에 부합. LUAD 확정, 추가 검사 불필요.',
    ),
    CaseReviewLog(
      caseId: caseId,
      action: ReviewAction.confirmed,
      reviewerName: '김의사',
      timestamp: now.subtract(const Duration(hours: 4)),
      opinionSnapshot: 'TP53 변이 확인, 표적치료 계획 검토 중.',
    ),
  ];
}