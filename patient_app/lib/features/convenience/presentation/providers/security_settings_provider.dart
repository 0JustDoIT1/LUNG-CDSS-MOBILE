import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock_repository.dart';

enum AppLockStatus { disabled, locked, unlocked }

class SecuritySettings {
  const SecuritySettings({
    required this.status,
    required this.biometricEnabled,
    this.message,
  });

  final AppLockStatus status;
  final bool biometricEnabled;
  final String? message;

  bool get appLockEnabled => status != AppLockStatus.disabled;
  bool get isLocked => status == AppLockStatus.locked;

  SecuritySettings copyWith({
    AppLockStatus? status,
    bool? biometricEnabled,
    String? message,
    bool clearMessage = false,
  }) {
    return SecuritySettings(
      status: status ?? this.status,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final appLockStorageProvider = Provider<AppLockStorage>((ref) {
  return SecureAppLockStorage();
});

final appLockRepositoryProvider = Provider<AppLockRepository>((ref) {
  return AppLockRepository(ref.watch(appLockStorageProvider));
});

final securitySettingsProvider =
    AsyncNotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
      SecuritySettingsNotifier.new,
    );

class SecuritySettingsNotifier extends AsyncNotifier<SecuritySettings> {
  AppLockRepository get _repository => ref.read(appLockRepositoryProvider);

  @override
  Future<SecuritySettings> build() async {
    final snapshot = await _repository.load();
    return SecuritySettings(
      status: snapshot.enabled ? AppLockStatus.locked : AppLockStatus.disabled,
      biometricEnabled: snapshot.biometricEnabled,
      message: snapshot.recoveredInvalidData
          ? '저장된 잠금 정보가 올바르지 않아 앱 잠금을 초기화했습니다.'
          : null,
    );
  }

  Future<bool> setPin(String pin) async {
    final previous = state.asData?.value;
    try {
      await _repository.enable(pin);
      state = const AsyncData(
        SecuritySettings(
          status: AppLockStatus.unlocked,
          biometricEnabled: false,
        ),
      );
      return true;
    } catch (_) {
      if (previous != null) {
        state = AsyncData(previous.copyWith(message: 'PIN을 안전하게 저장하지 못했습니다.'));
      }
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final valid = await _repository.verify(pin);
      if (valid) {
        final current = state.asData?.value;
        if (current != null) {
          state = AsyncData(
            current.copyWith(
              status: AppLockStatus.unlocked,
              clearMessage: true,
            ),
          );
        }
      }
      return valid;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disable(String currentPin) async {
    try {
      if (!await _repository.disable(currentPin)) return false;
      state = const AsyncData(
        SecuritySettings(
          status: AppLockStatus.disabled,
          biometricEnabled: false,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      return await _repository.changePin(currentPin, newPin);
    } catch (_) {
      return false;
    }
  }

  Future<bool> setBiometricEnabled(bool value) async {
    final current = state.asData?.value;
    if (current == null || !current.appLockEnabled) return false;
    try {
      await _repository.setBiometricEnabled(value);
      state = AsyncData(current.copyWith(biometricEnabled: value));
      return true;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    final current = state.asData?.value;
    if (current == null || !current.appLockEnabled || current.isLocked) return;
    state = AsyncData(current.copyWith(status: AppLockStatus.locked));
  }

  void unlockWithBiometrics() {
    final current = state.asData?.value;
    if (current == null || !current.appLockEnabled) return;
    state = AsyncData(current.copyWith(status: AppLockStatus.unlocked));
  }
}
