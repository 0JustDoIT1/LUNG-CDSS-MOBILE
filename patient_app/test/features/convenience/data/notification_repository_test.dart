import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/notification_repository.dart';

void main() {
  group('NotificationRepository.parseNotifications', () {
    test('rejects an array item that is not an object', () {
      expect(
        () => NotificationRepository.parseNotifications(<dynamic>['invalid']),
        throwsFormatException,
      );
    });

    test('parses an empty array', () {
      final notifications = NotificationRepository.parseNotifications(
        <dynamic>[],
      );

      expect(notifications, isEmpty);
    });
  });
}
