import 'package:flutter/foundation.dart';

/// 앱 잠금(PIN)/생체인증 사용 여부 — patient_app의 보안설정과 동일하게
/// 메모리에만 들고 있고(SharedPreferences 저장 안 함) 앱을 새로 켜면 기본값(앱잠금 켜짐)으로 돌아감.
/// PIN/생체인증 자체도 실제 서버/OS 연동 없이 patient_app과 동일하게 하드코딩된 목업(테스트 PIN "1234").
class SecuritySettingsController extends ChangeNotifier {
  bool _appLockEnabled = true;
  bool _biometricEnabled = false;
  bool _unlockedThisSession = false;

  bool get appLockEnabled => _appLockEnabled;
  bool get biometricEnabled => _biometricEnabled;

  /// 이번 앱 세션(로그인 이후)에 잠금을 이미 해제했는지 — 화면 이동할 때마다 다시 묻지 않기 위함.
  bool get unlockedThisSession => _unlockedThisSession;

  bool get needsUnlock => _appLockEnabled && !_unlockedThisSession;

  void setAppLockEnabled(bool value) {
    _appLockEnabled = value;
    if (!value) _biometricEnabled = false;
    notifyListeners();
  }

  void setBiometricEnabled(bool value) {
    if (!_appLockEnabled) return;
    _biometricEnabled = value;
    notifyListeners();
  }

  void markUnlocked() {
    _unlockedThisSession = true;
    notifyListeners();
  }

  /// 로그아웃 시 호출 — 다음 로그인부터 다시 잠금화면을 거치게 함.
  void resetUnlock() {
    _unlockedThisSession = false;
    notifyListeners();
  }
}
