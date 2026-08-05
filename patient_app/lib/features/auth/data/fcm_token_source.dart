import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class FcmTokenSource {
  Future<String?> getToken();

  Stream<String> get onTokenRefresh;
}

class FirebaseMessagingTokenSource implements FcmTokenSource {
  FirebaseMessagingTokenSource([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
