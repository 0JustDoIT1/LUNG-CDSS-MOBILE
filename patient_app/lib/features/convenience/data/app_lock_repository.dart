import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AppLockStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAppLockStorage implements AppLockStorage {
  SecureAppLockStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AppLockSnapshot {
  const AppLockSnapshot({
    required this.enabled,
    required this.biometricEnabled,
    this.recoveredInvalidData = false,
  });

  final bool enabled;
  final bool biometricEnabled;
  final bool recoveredInvalidData;
}

class AppLockRepository {
  AppLockRepository(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  static const appLockEnabledKey = 'app_lock_enabled';
  static const pinHashKey = 'pin_hash';
  static const pinSaltKey = 'pin_salt';
  static const biometricEnabledKey = 'biometric_enabled';
  static const _iterations = 50000;

  final AppLockStorage _storage;
  final Random _random;

  Future<AppLockSnapshot> load() async {
    final enabled = await _storage.read(appLockEnabledKey) == 'true';
    final biometric = await _storage.read(biometricEnabledKey) == 'true';
    if (!enabled) {
      return AppLockSnapshot(enabled: false, biometricEnabled: false);
    }

    final hash = await _storage.read(pinHashKey);
    final salt = await _storage.read(pinSaltKey);
    if (hash == null || hash.isEmpty || salt == null || salt.isEmpty) {
      await _clear();
      return const AppLockSnapshot(
        enabled: false,
        biometricEnabled: false,
        recoveredInvalidData: true,
      );
    }

    return AppLockSnapshot(enabled: true, biometricEnabled: biometric);
  }

  Future<void> enable(String pin) async {
    _validatePin(pin);
    final credentials = _createCredentials(pin);

    try {
      await _writeCredentials(credentials);
    } catch (_) {
      await _clear();
      rethrow;
    }
  }

  Future<bool> verify(String pin) async {
    if (!_isValidPin(pin)) return false;
    final hashValue = await _storage.read(pinHashKey);
    final saltValue = await _storage.read(pinSaltKey);
    if (hashValue == null || saltValue == null) return false;

    try {
      final expected = base64Url.decode(hashValue);
      final actual = _deriveKey(pin, base64Url.decode(saltValue));
      return _constantTimeEquals(expected, actual);
    } on FormatException {
      return false;
    }
  }

  Future<bool> disable(String currentPin) async {
    if (!await verify(currentPin)) return false;
    await _clear();
    return true;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    _validatePin(newPin);
    if (!await verify(currentPin)) return false;
    final oldHash = await _storage.read(pinHashKey);
    final oldSalt = await _storage.read(pinSaltKey);
    final credentials = _createCredentials(newPin);
    try {
      await _writeCredentials(credentials);
      return true;
    } catch (_) {
      if (oldSalt != null) await _storage.write(pinSaltKey, oldSalt);
      if (oldHash != null) await _storage.write(pinHashKey, oldHash);
      await _storage.write(appLockEnabledKey, 'true');
      rethrow;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(biometricEnabledKey, enabled ? 'true' : 'false');
  }

  Future<void> _clear() async {
    await _storage.delete(appLockEnabledKey);
    await _storage.delete(pinHashKey);
    await _storage.delete(pinSaltKey);
    await _storage.delete(biometricEnabledKey);
  }

  ({String hash, String salt}) _createCredentials(String pin) {
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return (
      hash: base64UrlEncode(_deriveKey(pin, salt)),
      salt: base64UrlEncode(salt),
    );
  }

  Future<void> _writeCredentials(({String hash, String salt}) value) async {
    await _storage.write(pinSaltKey, value.salt);
    await _storage.write(pinHashKey, value.hash);
    await _storage.write(appLockEnabledKey, 'true');
  }

  static void _validatePin(String pin) {
    if (!_isValidPin(pin)) {
      throw const FormatException('PIN must contain exactly four digits.');
    }
  }

  static bool _isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  static Uint8List _deriveKey(String pin, List<int> salt) {
    final password = utf8.encode(pin);
    final hmac = Hmac(sha256, password);
    final block = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..setAll(salt.length, const [0, 0, 0, 1]);
    var value = hmac.convert(block).bytes;
    final result = Uint8List.fromList(value);
    for (var iteration = 1; iteration < _iterations; iteration++) {
      value = hmac.convert(value).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= value[index];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }
}
