import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class NotificationClickSource {
  Future<String?> getInitialDeepLink();

  Stream<String?> get openedDeepLinks;
}

class FirebaseNotificationClickSource implements NotificationClickSource {
  FirebaseNotificationClickSource([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getInitialDeepLink() async {
    final message = await _messaging.getInitialMessage();
    return readDeepLink(message);
  }

  @override
  Stream<String?> get openedDeepLinks {
    return FirebaseMessaging.onMessageOpenedApp.map(readDeepLink);
  }

  static String? readDeepLink(RemoteMessage? message) {
    final value = message?.data['deep_link'];
    return value is String ? value : null;
  }
}
