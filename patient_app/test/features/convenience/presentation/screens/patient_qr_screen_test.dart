import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/convenience/presentation/screens/patient_qr_screen.dart';
import 'package:patient_app/features/intake/data/models/patient_qr_token.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';
import 'package:patient_app/features/intake/data/patient_qr_api.dart';
import 'package:patient_app/features/intake/data/patient_qr_repository.dart';
import 'package:patient_app/features/intake/presentation/providers/patient_qr_provider.dart';
import 'package:patient_app/features/intake/presentation/providers/intake_form_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('renders only the issued token and five-minute countdown', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pump();
    await tester.pump();

    final qr = tester.widget<PatientQrCode>(find.byType(PatientQrCode));
    expect(qr.data, 'temporary-server-token');
    expect(find.text('05:00 후 만료'), findsOneWidget);
    expect(find.textContaining('환자 이름'), findsNothing);
    expect(find.textContaining('환자번호'), findsNothing);
    expect(find.textContaining('Bearer'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expires on resume and issues a replacement QR', (tester) async {
    var now = DateTime(2026, 8, 6, 12);
    final repository = _FakeRepository(now: () => now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientQrClockProvider.overrideWithValue(() => now),
          patientQrRepositoryProvider.overrideWithValue(repository),
          intakeFormProvider.overrideWith(() => _SubmittedIntakeNotifier()),
        ],
        child: const MaterialApp(home: PatientQrScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    now = now.add(const Duration(seconds: 301));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('QR이 만료되었습니다.'), findsOneWidget);

    await tester.tap(find.text('새 QR 발급'));
    await tester.pump();
    await tester.pump();
    expect(repository.calls, 2);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}

Widget _app(PatientQrRepository repository) => ProviderScope(
  overrides: [
    patientQrRepositoryProvider.overrideWithValue(repository),
    intakeFormProvider.overrideWith(() => _SubmittedIntakeNotifier()),
  ],
  child: const MaterialApp(home: PatientQrScreen()),
);

class _SubmittedIntakeNotifier extends IntakeFormNotifier {
  @override
  Future<IntakeForm> build() async => IntakeForm(
    id: 'intake',
    content: const IntakeContent(
      status: IntakeStatus.submitted,
      questions: <IntakeQuestion>[],
    ),
    submittedAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

class _FakeRepository extends PatientQrRepository {
  _FakeRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(PatientQrApi(ApiClient(dio: Dio())));

  final DateTime Function() _now;
  int calls = 0;

  @override
  Future<PatientQrToken> issue() async {
    calls++;
    return PatientQrToken(
      token: calls == 1 ? 'temporary-server-token' : 'replacement-token',
      expiresIn: 300,
      expiresAt: _now().add(const Duration(seconds: 300)),
    );
  }
}
