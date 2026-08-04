/// 케이스 검토 이력 한 건.
/// CaseReviewLog(action=confirmed/edited)와 대응.
///
/// TODO: 실제 연결 시 이 클래스에 fromJson() 추가하고
/// mockReviewLogs() 대신 API 응답으로 교체.
class CaseReviewLog {
  final String caseId;
  final ReviewAction action;
  final String reviewerName;
  final DateTime timestamp;
  final String opinionSnapshot; // 검토 당시 소견 스냅샷

  const CaseReviewLog({
    required this.caseId,
    required this.action,
    required this.reviewerName,
    required this.timestamp,
    required this.opinionSnapshot,
  });
}

enum ReviewAction {
  confirmed, // 승인 (AI값 그대로)
  edited; // 반려 후 수정

  String get label => switch (this) {
        ReviewAction.confirmed => '승인',
        ReviewAction.edited => '수정(반려)',
      };
}