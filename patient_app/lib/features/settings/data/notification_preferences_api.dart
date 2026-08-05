import '../../../core/network/api_client.dart';
import 'models/notification_preference.dart';

class NotificationPreferencesApi {
  NotificationPreferencesApi(this._client);
  final ApiClient _client;

  Future<List<dynamic>> fetchNotificationPreferences() async {
    final response = await _client.get<dynamic>(
      '/api/auth/notifications/preferences/',
    );
    if (response.data is! List<dynamic>) {
      throw const FormatException('알림 설정 응답은 배열이어야 합니다.');
    }
    return response.data! as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateNotificationPreference({
    required NotificationPreferenceCategory category,
    required bool enabled,
  }) async {
    final response = await _client.patch<dynamic>(
      '/api/auth/notifications/preferences/update/',
      data: <String, dynamic>{
        'category': category.apiValue,
        'enabled': enabled,
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('알림 설정 수정 응답은 객체여야 합니다.');
    }
    return response.data! as Map<String, dynamic>;
  }
}
