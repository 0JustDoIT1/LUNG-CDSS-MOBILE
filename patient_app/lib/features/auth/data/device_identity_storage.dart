import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentityStorage {
  DeviceIdentityStorage({
    FlutterSecureStorage? storage,
    String Function()? idGenerator,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _idGenerator = idGenerator ?? _generateUuidV4;

  static const String _deviceIdKey = 'patient_app_device_id';
  static const String _registeredFcmTokenKey =
      'patient_app_registered_fcm_token';

  final FlutterSecureStorage _storage;
  final String Function() _idGenerator;

  Future<String> getOrCreateDeviceId() async {
    final stored = await _storage.read(key: _deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final generated = _idGenerator();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);

  Future<String?> readRegisteredFcmToken() {
    return _storage.read(key: _registeredFcmTokenKey);
  }

  Future<void> saveRegisteredFcmToken(String token) {
    return _storage.write(key: _registeredFcmTokenKey, value: token);
  }

  Future<void> clearRegisteredFcmToken() {
    return _storage.delete(key: _registeredFcmTokenKey);
  }

  static String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
