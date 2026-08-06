import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/data/models/auth_state.dart';
import 'package:patient_app/features/auth/data/kakao_sign_in_service.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:patient_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Kakao button calls the Kakao AuthNotifier branch', (
    tester,
  ) async {
    final notifier = _LoginAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pump();

    expect(notifier.lastProvider, 'kakao');
  });

  testWidgets('Kakao cancellation does not show a generic error Snackbar', (
    tester,
  ) async {
    final notifier = _LoginAuthNotifier(cancel: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('카카오로 계속하기'));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}

class _LoginAuthNotifier extends AuthNotifier {
  _LoginAuthNotifier({this.cancel = false});

  final bool cancel;
  String? lastProvider;

  @override
  Future<AuthState> build() async => const AuthState(isNewUser: false);

  @override
  Future<void> signInWithSocial({required String provider}) async {
    lastProvider = provider;
    state = cancel
        ? const AsyncError(SocialLoginCancelledException(), StackTrace.empty)
        : const AsyncData(AuthState(isNewUser: false));
  }
}
