import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/app_lock_repository.dart';

void main() {
  group('AppLockRepository', () {
    test('PIN 설정 후 원문 없이 잠금 상태를 복원한다', () async {
      final storage = _MemoryStorage();
      final repository = AppLockRepository(storage, random: Random(1));

      await repository.enable('1234');

      expect(storage.values[AppLockRepository.appLockEnabledKey], 'true');
      expect(storage.values.values, isNot(contains('1234')));
      expect(storage.values[AppLockRepository.pinHashKey], isNotEmpty);
      expect(storage.values[AppLockRepository.pinSaltKey], isNotEmpty);
      expect((await repository.load()).enabled, isTrue);
    });

    test('올바른 PIN만 검증한다', () async {
      final repository = AppLockRepository(_MemoryStorage(), random: Random(2));
      await repository.enable('2580');

      expect(await repository.verify('2580'), isTrue);
      expect(await repository.verify('0000'), isFalse);
      expect(await repository.verify('258'), isFalse);
    });

    test('잠금 해제는 PIN 확인 후 모든 값을 삭제한다', () async {
      final storage = _MemoryStorage();
      final repository = AppLockRepository(storage, random: Random(3));
      await repository.enable('1111');
      await repository.setBiometricEnabled(true);

      expect(await repository.disable('9999'), isFalse);
      expect((await repository.load()).enabled, isTrue);
      expect(await repository.disable('1111'), isTrue);
      expect(storage.values, isEmpty);
    });

    test('PIN 변경 후에는 새 PIN만 유효하다', () async {
      final repository = AppLockRepository(_MemoryStorage(), random: Random(4));
      await repository.enable('1234');

      expect(await repository.changePin('9999', '5678'), isFalse);
      expect(await repository.verify('1234'), isTrue);
      expect(await repository.changePin('1234', '5678'), isTrue);
      expect(await repository.verify('1234'), isFalse);
      expect(await repository.verify('5678'), isTrue);
    });

    test('enabled 상태에 PIN 정보가 없으면 안전하게 초기화한다', () async {
      final storage = _MemoryStorage()
        ..values[AppLockRepository.appLockEnabledKey] = 'true';
      final repository = AppLockRepository(storage);

      final snapshot = await repository.load();

      expect(snapshot.enabled, isFalse);
      expect(snapshot.recoveredInvalidData, isTrue);
      expect(storage.values, isEmpty);
    });

    test('저장 오류 시 잠금을 활성화하지 않는다', () async {
      final storage = _MemoryStorage(failWrites: true);
      final repository = AppLockRepository(storage, random: Random(5));

      await expectLater(repository.enable('1234'), throwsA(anything));
      expect(storage.values, isEmpty);
    });
  });
}

class _MemoryStorage implements AppLockStorage {
  _MemoryStorage({this.failWrites = false});

  final bool failWrites;
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage unavailable');
    values[key] = value;
  }
}
