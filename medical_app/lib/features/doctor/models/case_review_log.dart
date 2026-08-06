import '../../../core/utils/datetime_utils.dart';

/// 케이스 검토 이력 한 건. GET /api/cases/{case_id}/review-log/ 응답 구조(실제 확인됨).
class CaseReviewLog {
  final String caseId;
  final ReviewAction action;
  final String reviewerName;
  final DateTime timestamp;
  final String opinionSnapshot; // 검토 당시 소견 스냅샷(note_at_time)
  final String? subtypeAtTime; // 검토 당시 확정/수정된 아형(LUAD/LUSC)

  const CaseReviewLog({
    required this.caseId,
    required this.action,
    required this.reviewerName,
    required this.timestamp,
    required this.opinionSnapshot,
    this.subtypeAtTime,
  });

  factory CaseReviewLog.fromJson(String caseId, Map<String, dynamic> json) {
    final actionValue = json['action'] as String?;
    return CaseReviewLog(
      caseId: caseId,
      action: actionValue == 'edited' ? ReviewAction.edited : ReviewAction.confirmed,
      reviewerName: json['reviewer_name'] as String? ?? '',
      timestamp: parseServerDateTime(json['created_at'] as String),
      opinionSnapshot: json['note_at_time'] as String? ?? '',
      subtypeAtTime: json['subtype_at_time'] as String?,
    );
  }
}

enum ReviewAction {
  confirmed, // 승인 (AI값 그대로)
  edited; // 반려 후 수정

  String get label => switch (this) {
        ReviewAction.confirmed => '승인',
        ReviewAction.edited => '수정(반려)',
      };
}