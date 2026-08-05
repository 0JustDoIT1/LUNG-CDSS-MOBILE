import 'models/notification_preference.dart';
import 'notification_preferences_api.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository(this._api);
  final NotificationPreferencesApi _api;

  Future<List<NotificationPreference>> fetchNotificationPreferences() async {
    final seen = <NotificationPreferenceCategory>{};
    final values = (await _api.fetchNotificationPreferences())
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('알림 설정 항목은 객체여야 합니다.');
          }
          final value = NotificationPreference.fromJson(item);
          if (!seen.add(value.category)) {
            throw const FormatException('중복된 알림 설정 카테고리입니다.');
          }
          return value;
        })
        .toList(growable: false);
    if (seen.length != NotificationPreferenceCategory.values.length) {
      throw const FormatException('필수 알림 설정이 누락되었습니다.');
    }
    return values;
  }

  Future<NotificationPreference> updateNotificationPreference({
    required NotificationPreferenceCategory category,
    required bool enabled,
  }) async => NotificationPreference.fromJson(
    await _api.updateNotificationPreference(
      category: category,
      enabled: enabled,
    ),
  );
}
