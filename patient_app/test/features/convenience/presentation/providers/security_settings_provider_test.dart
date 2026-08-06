import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/app_lock_repository.dart';
import 'package:patient_app/features/convenience/presentation/providers/security_settings_provider.dart';

void main() {
  test('PIN 설정, 세션 잠금, 올바른 PIN 해제를 처리한다', () async {
    final storage = _MemoryStorage();
    final container = ProviderContainer(
      overrides: [appLockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(securitySettingsProvider.future)).status,
      AppLockStatus.disabled,
    );

    final notifier = container.read(securitySettingsProvider.notifier);
    expect(await notifier.setPin('1234'), isTrue);
    expect(
      container.read(securitySettingsProvider).value?.status,
      AppLockStatus.unlocked,
    );

    notifier.lock();
    expect(
      container.read(securitySettingsProvider).value?.status,
      AppLockStatus.locked,
    );
    expect(await notifier.verifyPin('0000'), isFalse);
    expect(
      container.read(securitySettingsProvider).value?.status,
      AppLockStatus.locked,
    );
    expect(await notifier.verifyPin('1234'), isTrue);
    expect(
      container.read(securitySettingsProvider).value?.status,
      AppLockStatus.unlocked,
    );
  });

  test('재시작에 해당하는 새 ProviderContainer는 잠긴 상태로 복원한다', () async {
    final storage = _MemoryStorage();
    final first = ProviderContainer(
      overrides: [appLockStorageProvider.overrideWithValue(storage)],
    );
    await first.read(securitySettingsProvider.future);
    await first.read(securitySettingsProvider.notifier).setPin('2468');
    first.dispose();

    final restarted = ProviderContainer(
      overrides: [appLockStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(restarted.dispose);
    expect(
      (await restarted.read(securitySettingsProvider.future)).status,
      AppLockStatus.locked,
    );
  });
}

class _MemoryStorage implements AppLockStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
