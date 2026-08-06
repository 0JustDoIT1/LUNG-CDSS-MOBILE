import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/intake/data/models/patient_qr_token.dart';
import 'package:patient_app/features/intake/data/patient_qr_api.dart';
import 'package:patient_app/features/intake/data/patient_qr_repository.dart';
import 'package:patient_app/features/intake/presentation/providers/patient_qr_provider.dart';

void main() {
  test('issues, replaces the token, and expires by absolute time', () async {
    var now = DateTime(2026, 8, 6, 12);
    final repository = _FakeRepository(now: () => now);
    final container = ProviderContainer(
      overrides: [
        patientQrClockProvider.overrideWithValue(() => now),
        patientQrRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(patientQrProvider, (_, _) {});
    addTearDown(subscription.close);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.calls, 1);
    expect(container.read(patientQrProvider).value?.token, 'token-1');
    expect(container.read(patientQrProvider).remainingSeconds, 300);

    await container.read(patientQrProvider.notifier).issue();
    expect(container.read(patientQrProvider).value?.token, 'token-2');

    now = now.add(const Duration(seconds: 301));
    container.read(patientQrProvider.notifier).recalculateRemainingTime();
    expect(container.read(patientQrProvider).status, PatientQrStatus.expired);
  });

  test('prevents duplicate requests while one is in flight', () async {
    final pending = Completer<PatientQrToken>();
    final repository = _FakeRepository(pending: pending);
    final container = ProviderContainer(
      overrides: [patientQrRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(patientQrProvider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(patientQrProvider.notifier);
    unawaited(notifier.issue());
    unawaited(notifier.issue());
    expect(repository.calls, 1);

    pending.complete(_token('done', DateTime.now()));
    await Future<void>.delayed(Duration.zero);
  });

  test('maps required API error categories to safe messages', () {
    expect(
      patientQrErrorMessage(const ApiException(message: 'x', statusCode: 401)),
      contains('로그인'),
    );
    expect(
      patientQrErrorMessage(const ApiException(message: 'x', statusCode: 403)),
      contains('환자 권한'),
    );
    expect(
      patientQrErrorMessage(const ApiException(message: 'x', statusCode: 500)),
      contains('서버 오류'),
    );
    expect(
      patientQrErrorMessage(const ApiException(message: 'x', code: 'TIMEOUT')),
      contains('지연'),
    );
    expect(
      patientQrErrorMessage(
        const ApiException(message: 'x', code: 'CONNECTION_ERROR'),
      ),
      contains('네트워크'),
    );
  });
}

PatientQrToken _token(String value, DateTime now) => PatientQrToken(
  token: value,
  expiresIn: 300,
  expiresAt: now.add(const Duration(seconds: 300)),
);

class _FakeRepository extends PatientQrRepository {
  _FakeRepository({DateTime Function()? now, this.pending})
    : _now = now ?? DateTime.now,
      super(PatientQrApi(ApiClient(dio: Dio())));

  final DateTime Function() _now;
  final Completer<PatientQrToken>? pending;
  int calls = 0;

  @override
  Future<PatientQrToken> issue() async {
    calls++;
    final completer = pending;
    if (completer != null) return completer.future;
    return _token('token-$calls', _now());
  }
}
