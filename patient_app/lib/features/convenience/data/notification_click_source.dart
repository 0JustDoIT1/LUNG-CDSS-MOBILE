import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_display_service.dart';

abstract interface class NotificationClickSource {
  Future<String?> getInitialDeepLink();

  Stream<String?> get openedDeepLinks;
}

class FirebaseNotificationClickSource implements NotificationClickSource {
  FirebaseNotificationClickSource([
    FirebaseMessaging? messaging,
    this._displayService,
  ]) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final NotificationDisplayService? _displayService;

  @override
  Future<String?> getInitialDeepLink() async {
    final message = await _messaging.getInitialMessage();
    final firebaseDeepLink = readDeepLink(message);
    if (firebaseDeepLink != null) return firebaseDeepLink;
    return _displayService?.getInitialDeepLink();
  }

  @override
  Stream<String?> get openedDeepLinks {
    final displayService = _displayService;
    if (displayService == null) {
      return FirebaseMessaging.onMessageOpenedApp.map(readDeepLink);
    }

    late final StreamController<String?> controller;
    StreamSubscription<String?>? firebaseSubscription;
    StreamSubscription<String?>? localSubscription;
    controller = StreamController<String?>.broadcast(
      onListen: () {
        firebaseSubscription = FirebaseMessaging.onMessageOpenedApp
            .map(readDeepLink)
            .listen(controller.add, onError: controller.addError);
        localSubscription = displayService.openedDeepLinks.listen(
          controller.add,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await firebaseSubscription?.cancel();
        await localSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  static String? readDeepLink(RemoteMessage? message) {
    final value = message?.data['deep_link'];
    return value is String ? value : null;
  }
}
