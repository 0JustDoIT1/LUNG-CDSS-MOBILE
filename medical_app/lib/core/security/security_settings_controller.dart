import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 잠금(PIN)/생체인증 설정.
/// PIN은 flutter_secure_storage(iOS Keychain / Android Keystore)에, 켜짐 여부는
/// SharedPreferences에 저장 — 앱을 껐다 켜도 유지됨. PIN은 사용자가 직접 설정/변경한다.
class SecuritySettingsController extends ChangeNotifier {
  SecuritySettingsController({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyPin = 'security.pin';
  static const _keyAppLockEnabled = 'security.appLockEnabled';
  static const _keyBiometricEnabled = 'security.biometricEnabled';

  final FlutterSecureStorage _secureStorage;

  bool _appLockEnabled = true;
  bool _biometricEnabled = false;
  bool _unlockedThisSession = false;
  String? _pin;
  bool _isLoaded = false;

  bool get appLockEnabled => _appLockEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;

  /// 저장된 설정을 아직 못 불러왔으면(앱 켜진 직후) true — 이 상태에서 needsUnlock을 판단하면
  /// PIN이 실제로는 있는데 "아직 안 불러왔을 뿐"인 걸 "없다"고 오판해서 설정화면으로 잘못 보낼 수 있음.
  bool get isLoaded => _isLoaded;

  /// 이번 앱 세션(로그인 이후)에 잠금을 이미 해제했는지 — 화면 이동할 때마다 다시 묻지 않기 위함.
  bool get unlockedThisSession => _unlockedThisSession;

  bool get needsUnlock => _appLockEnabled && !_unlockedThisSession;

  /// 앱잠금은 켜져 있는데 PIN을 아직 한 번도 설정 안 한 경우 — 잠금해제 대신 PIN 설정 화면으로 보내야 함.
  bool get needsPinSetup => _appLockEnabled && !hasPin;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _appLockEnabled = prefs.getBool(_keyAppLockEnabled) ?? true;
    _biometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    _pin = await _secureStorage.read(key: _keyPin);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _appLockEnabled = value;
    if (!value) _biometricEnabled = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, value);
    if (!value) await prefs.setBool(_keyBiometricEnabled, false);
  }

  Future<void> setBiometricEnabled(bool value) async {
    if (!_appLockEnabled) return;
    _biometricEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, value);
  }

  /// 새 PIN 저장(최초 설정 또는 변경).
  Future<void> setPin(String pin) async {
    _pin = pin;
    await _secureStorage.write(key: _keyPin, value: pin);
    notifyListeners();
  }

  bool verifyPin(String pin) => hasPin && _pin == pin;

  void markUnlocked() {
    _unlockedThisSession = true;
    notifyListeners();
  }

  /// 로그아웃 시 호출 — 다음 로그인부터 다시 잠금화면을 거치게 함. PIN 자체는 기기에 남겨둠.
  void resetUnlock() {
    _unlockedThisSession = false;
    notifyListeners();
  }
}
