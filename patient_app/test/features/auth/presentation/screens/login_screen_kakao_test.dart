import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/data/models/auth_state.dart';
import 'package:patient_app/features/auth/data/kakao_sign_in_service.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:patient_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Google과 Kakao만 같은 크기로 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _LoginAuthNotifier())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('네이버로 계속하기'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('google-login-button'))),
      tester.getSize(find.byKey(const Key('kakao-login-button'))),
    );
    expect(
      tester.getSize(find.byKey(const Key('google-login-button'))).height,
      52,
    );
  });

  testWidgets('Google button calls the Google AuthNotifier branch', (
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

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pump();

    expect(notifier.lastProvider, 'google');
  });

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

  testWidgets('로그인 처리 중 다른 소셜 버튼의 중복 클릭을 막는다', (tester) async {
    final completer = Completer<void>();
    final notifier = _LoginAuthNotifier(pending: completer);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('kakao-login-button')));
    await tester.pump();

    expect(notifier.calls, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('작은 화면에서 overflow가 발생하지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _LoginAuthNotifier())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _LoginAuthNotifier extends AuthNotifier {
  _LoginAuthNotifier({this.cancel = false, this.pending});

  final bool cancel;
  final Completer<void>? pending;
  String? lastProvider;
  int calls = 0;

  @override
  Future<AuthState> build() async => const AuthState(isNewUser: false);

  @override
  Future<void> signInWithSocial({required String provider}) async {
    calls++;
    lastProvider = provider;
    await pending?.future;
    state = cancel
        ? const AsyncError(SocialLoginCancelledException(), StackTrace.empty)
        : const AsyncData(AuthState(isNewUser: false));
  }
}
