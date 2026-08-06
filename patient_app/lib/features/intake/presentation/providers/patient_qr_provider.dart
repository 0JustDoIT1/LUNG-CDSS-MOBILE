import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/models/patient_qr_token.dart';
import '../../data/patient_qr_api.dart';
import '../../data/patient_qr_repository.dart';

enum PatientQrStatus { loading, data, error, expired }

class PatientQrState {
  const PatientQrState._({
    required this.status,
    this.value,
    this.remainingSeconds = 0,
    this.error,
  });

  const PatientQrState.loading() : this._(status: PatientQrStatus.loading);

  const PatientQrState.data(PatientQrToken value, int remainingSeconds)
    : this._(
        status: PatientQrStatus.data,
        value: value,
        remainingSeconds: remainingSeconds,
      );

  const PatientQrState.error(Object error)
    : this._(status: PatientQrStatus.error, error: error);

  const PatientQrState.expired(PatientQrToken value)
    : this._(status: PatientQrStatus.expired, value: value);

  final PatientQrStatus status;
  final PatientQrToken? value;
  final int remainingSeconds;
  final Object? error;
}

final patientQrClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final patientQrApiProvider = Provider<PatientQrApi>((ref) {
  return PatientQrApi(ref.watch(apiClientProvider));
});

final patientQrRepositoryProvider = Provider<PatientQrRepository>((ref) {
  return PatientQrRepository(
    ref.watch(patientQrApiProvider),
    now: ref.watch(patientQrClockProvider),
  );
});

final patientQrProvider =
    NotifierProvider.autoDispose<PatientQrNotifier, PatientQrState>(
      PatientQrNotifier.new,
    );

class PatientQrNotifier extends Notifier<PatientQrState> {
  Timer? _timer;
  bool _requestInFlight = false;

  @override
  PatientQrState build() {
    ref.onDispose(() => _timer?.cancel());
    Future<void>.microtask(issue);
    return const PatientQrState.loading();
  }

  Future<void> issue() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    _timer?.cancel();
    state = const PatientQrState.loading();

    try {
      final value = await ref.read(patientQrRepositoryProvider).issue();
      if (!ref.mounted) return;
      _setFromExpiration(value);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (ref.mounted) _setFromExpiration(value);
      });
    } catch (error) {
      if (ref.mounted) state = PatientQrState.error(error);
    } finally {
      _requestInFlight = false;
    }
  }

  void recalculateRemainingTime() {
    final value = state.value;
    if (value != null) _setFromExpiration(value);
  }

  void _setFromExpiration(PatientQrToken value) {
    final milliseconds = value.expiresAt
        .difference(ref.read(patientQrClockProvider)())
        .inMilliseconds;
    if (milliseconds <= 0) {
      _timer?.cancel();
      state = PatientQrState.expired(value);
      return;
    }
    final seconds = (milliseconds + 999) ~/ 1000;
    state = PatientQrState.data(value, seconds);
  }
}

String patientQrErrorMessage(Object? error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 400:
        return 'QR 발급 요청을 확인해주세요.';
      case 401:
        return '로그인 세션이 만료되었습니다. 다시 로그인해주세요.';
      case 403:
        return '환자 권한이 필요한 기능입니다.';
      case 500:
      case 503:
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
    if (error.code == 'TIMEOUT') {
      return '서버 응답이 지연되고 있습니다. 다시 시도해주세요.';
    }
    if (error.code == 'CONNECTION_ERROR') {
      return '네트워크 연결을 확인해주세요.';
    }
  }
  if (error is FormatException) {
    return 'QR 발급 응답을 확인할 수 없습니다.';
  }
  return 'QR을 발급하지 못했습니다. 다시 시도해주세요.';
}
