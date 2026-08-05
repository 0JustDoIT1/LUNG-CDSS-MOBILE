import '../../../core/network/api_client.dart';

class NotificationApi {
  NotificationApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> getNotifications() async {
    final response = await _apiClient.get<dynamic>(
      '/api/communication/notifications/',
    );
    final data = response.data;

    if (data is! List<dynamic>) {
      throw const FormatException('알림 목록 응답은 배열이어야 합니다.');
    }

    return data;
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      throw ArgumentError('notificationId는 비어 있을 수 없습니다.');
    }

    await _apiClient.post<void>(
      '/api/communication/notifications/$notificationId/read/',
    );
  }
}
