import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/notification_click_source.dart';

void main() {
  test('reads only the confirmed deep_link payload key', () {
    expect(
      FirebaseNotificationClickSource.readDeepLink(
        const RemoteMessage(data: {'deep_link': '/results/case-id'}),
      ),
      '/results/case-id',
    );
    expect(
      FirebaseNotificationClickSource.readDeepLink(
        const RemoteMessage(data: {'target_id': 'case-id'}),
      ),
      isNull,
    );
    expect(
      FirebaseNotificationClickSource.readDeepLink(
        const RemoteMessage(data: {'deep_link': 1}),
      ),
      isNull,
    );
  });
}
