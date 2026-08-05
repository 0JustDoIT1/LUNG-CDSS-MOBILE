enum NotificationPreferenceCategory {
  all('all'),
  medication('medication'),
  appointment('appointment'),
  chat('chat'),
  triage('triage'),
  caseReview('case_review');

  const NotificationPreferenceCategory(this.apiValue);
  final String apiValue;

  static NotificationPreferenceCategory parse(String value) {
    for (final category in values) {
      if (category.apiValue == value) return category;
    }
    throw const FormatException('알 수 없는 알림 설정 카테고리입니다.');
  }
}

class NotificationPreference {
  const NotificationPreference({required this.category, required this.enabled});
  final NotificationPreferenceCategory category;
  final bool enabled;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final enabled = json['enabled'];
    if (category is! String || enabled is! bool) {
      throw const FormatException('알림 설정 형식이 올바르지 않습니다.');
    }
    return NotificationPreference(
      category: NotificationPreferenceCategory.parse(category),
      enabled: enabled,
    );
  }
}
