import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/guardian/data/models/guardian_invite.dart';
import 'package:patient_app/features/guardian/presentation/providers/guardian_data_provider.dart';
import 'package:patient_app/features/settings/presentation/screens/guardian_link_screen.dart';

void main() {
  testWidgets('shows only the invite code returned by the provider', (
    tester,
  ) async {
    final notifier = _InviteNotifier();
    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    expect(find.text('SERVER1'), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-invite-code')), findsOneWidget);
  });

  testWidgets('new code action requests and displays another server code', (
    tester,
  ) async {
    final notifier = _InviteNotifier();
    await tester.pumpWidget(_app(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guardian-invite-create-button')));
    await tester.pumpAndSettle();
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('새 코드 생성'),
    );
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(notifier.createCount, 1);
    expect(find.text('SERVER2'), findsOneWidget);
  });

  for (final scenario in <(Object, String)>[
    (
      const ApiException(message: 'unauthorized', statusCode: 401),
      '로그인이 만료되었습니다. 다시 로그인해주세요.',
    ),
    (
      const ApiException(message: 'forbidden', statusCode: 403),
      '보호자 초대코드를 생성할 환자 권한이 없습니다.',
    ),
    (
      const ApiException(message: 'server', statusCode: 500),
      '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
    ),
    (
      const ApiException(message: 'timeout', code: 'TIMEOUT'),
      '서버 응답 시간이 초과되었습니다.',
    ),
    (
      const ApiException(message: 'connection', code: 'CONNECTION_ERROR'),
      '네트워크 연결을 확인해주세요.',
    ),
  ]) {
    testWidgets('shows safe invite error: ${scenario.$2}', (tester) async {
      await tester.pumpWidget(_app(_InviteNotifier(error: scenario.$1)));
      await tester.pumpAndSettle();

      expect(find.text(scenario.$2), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guardian-invite-retry-button')),
        findsOneWidget,
      );
    });
  }
}

Widget _app(GuardianInviteNotifier notifier) {
  return ProviderScope(
    overrides: [guardianInviteProvider.overrideWith(() => notifier)],
    child: const MaterialApp(home: GuardianLinkScreen()),
  );
}

class _InviteNotifier extends GuardianInviteNotifier {
  _InviteNotifier({this.error});

  final Object? error;
  int createCount = 0;

  @override
  Future<GuardianInvite> build() async {
    if (error case final value?) throw value;
    return _invite('SERVER1');
  }

  @override
  Future<void> createNewInvite() async {
    createCount += 1;
    state = AsyncData(_invite('SERVER2'));
  }
}

GuardianInvite _invite(String code) {
  return GuardianInvite(
    id: 'link-id',
    inviteCode: code,
    guardianName: null,
    invitedAt: DateTime(2026, 8, 6),
    acceptedAt: null,
  );
}
