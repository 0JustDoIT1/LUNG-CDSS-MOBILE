import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySettings {
  const SecuritySettings({
    required this.appLockEnabled,
    required this.biometricEnabled,
  });

  final bool appLockEnabled;
  final bool biometricEnabled;

  SecuritySettings copyWith({
    bool? appLockEnabled,
    bool? biometricEnabled,
  }) {
    return SecuritySettings(
      appLockEnabled:
          appLockEnabled ?? this.appLockEnabled,
      biometricEnabled:
          biometricEnabled ?? this.biometricEnabled,
    );
  }
}

final securitySettingsProvider = NotifierProvider<
    SecuritySettingsNotifier,
    SecuritySettings>(
  SecuritySettingsNotifier.new,
);

class SecuritySettingsNotifier
    extends Notifier<SecuritySettings> {
  @override
  SecuritySettings build() {
    return const SecuritySettings(
      appLockEnabled: true,
      biometricEnabled: false,
    );
  }

  void setAppLockEnabled(bool value) {
    state = state.copyWith(
      appLockEnabled: value,
      biometricEnabled:
          value ? state.biometricEnabled : false,
    );
  }

  void setBiometricEnabled(bool value) {
    if (!state.appLockEnabled) {
      return;
    }

    state = state.copyWith(
      biometricEnabled: value,
    );
  }
}