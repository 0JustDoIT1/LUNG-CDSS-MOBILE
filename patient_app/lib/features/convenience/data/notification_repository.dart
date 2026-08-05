import 'models/patient_notification.dart';
import 'notification_api.dart';

class NotificationRepository {
  NotificationRepository(this._notificationApi);

  final NotificationApi _notificationApi;

  Future<List<PatientNotification>> getNotifications() async {
    final notifications = await _notificationApi.getNotifications();
    return parseNotifications(notifications);
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationApi.markAsRead(notificationId);
  }

  static List<PatientNotification> parseNotifications(
    List<dynamic> notifications,
  ) {
    return notifications
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('알림 목록의 각 항목은 객체여야 합니다.');
          }

          return PatientNotification.fromJson(item);
        })
        .toList(growable: false);
  }
}
