import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/models/patient_notification.dart';
import 'package:patient_app/features/convenience/presentation/providers/notification_provider.dart';

void main() {
  group('unreadNotificationCountProvider', () {
    test('counts only unread notifications', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) async => <PatientNotification>[
              _notification(id: '1', isRead: false),
              _notification(id: '2', isRead: true),
              _notification(id: '3', isRead: false),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsProvider.future);

      expect(container.read(unreadNotificationCountProvider), 2);
    });

    test('returns zero for an empty list', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) async => <PatientNotification>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsProvider.future);

      expect(container.read(unreadNotificationCountProvider), 0);
    });

    test('returns null while loading or after an error', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith(
            (ref) =>
                Future<List<PatientNotification>>.error(Exception('failed')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        notificationsProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(container.read(unreadNotificationCountProvider), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(unreadNotificationCountProvider), isNull);
    });
  });
}

PatientNotification _notification({required String id, required bool isRead}) {
  return PatientNotification(
    id: id,
    category: 'medication',
    title: 'Title',
    body: 'Body',
    deepLink: null,
    isRead: isRead,
    createdAt: DateTime(2026, 8, 5),
  );
}
