import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/models/patient_notification.dart';

void main() {
  group('PatientNotification.fromJson', () {
    test('parses valid JSON', () {
      final notification = PatientNotification.fromJson({
        'id': 'notification-uuid',
        'category': 'medication',
        'title': 'Medication reminder',
        'body': 'It is time to take your medication.',
        'deep_link': '/results/case-id',
        'is_read': false,
        'created_at': '2026-08-05T09:00:00+09:00',
      });

      expect(notification.id, 'notification-uuid');
      expect(notification.category, 'medication');
      expect(notification.title, 'Medication reminder');
      expect(notification.body, 'It is time to take your medication.');
      expect(notification.deepLink, '/results/case-id');
      expect(notification.isRead, isFalse);
      expect(
        notification.createdAt,
        DateTime.parse('2026-08-05T09:00:00+09:00'),
      );
    });

    test('keeps a null deep link as null', () {
      final notification = PatientNotification.fromJson({
        'id': 'notification-uuid',
        'category': 'appointment',
        'title': 'Appointment reminder',
        'body': 'You have an upcoming appointment.',
        'deep_link': null,
        'is_read': true,
        'created_at': '2026-08-05T09:00:00+09:00',
      });

      expect(notification.deepLink, isNull);
    });

    test('keeps an empty category unchanged', () {
      final notification = PatientNotification.fromJson({
        'id': 'notification-uuid',
        'category': '',
        'title': 'Notification',
        'body': 'Notification body',
        'deep_link': null,
        'is_read': false,
        'created_at': '2026-08-05T09:00:00+09:00',
      });

      expect(notification.category, isEmpty);
    });

    test('rejects an invalid required field type', () {
      expect(
        () => PatientNotification.fromJson({
          'id': 1,
          'category': 'chat',
          'title': 'Notification',
          'body': 'Notification body',
          'deep_link': null,
          'is_read': false,
          'created_at': '2026-08-05T09:00:00+09:00',
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid date', () {
      expect(
        () => PatientNotification.fromJson({
          'id': 'notification-uuid',
          'category': 'triage',
          'title': 'Notification',
          'body': 'Notification body',
          'deep_link': null,
          'is_read': false,
          'created_at': 'not-a-date',
        }),
        throwsFormatException,
      );
    });
  });
}
