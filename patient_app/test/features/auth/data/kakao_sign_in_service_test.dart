import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/kakao_sign_in_service.dart';

void main() {
  test('uses Kakao Talk access token when Kakao Talk succeeds', () async {
    final client = _FakeKakaoClient(talkInstalled: true);

    final token = await KakaoSignInService(
      client: client,
    ).signInAndGetAccessToken();

    expect(token, 'talk-access-token');
    expect(client.talkCalls, 1);
    expect(client.accountCalls, 0);
  });

  test('falls back to Kakao Account when Kakao Talk fails', () async {
    final client = _FakeKakaoClient(
      talkInstalled: true,
      talkError: StateError('talk unavailable'),
    );

    final token = await KakaoSignInService(
      client: client,
    ).signInAndGetAccessToken();

    expect(token, 'account-access-token');
    expect(client.talkCalls, 1);
    expect(client.accountCalls, 1);
  });

  test('uses Kakao Account when Kakao Talk is not installed', () async {
    final client = _FakeKakaoClient(talkInstalled: false);

    final token = await KakaoSignInService(
      client: client,
    ).signInAndGetAccessToken();

    expect(token, 'account-access-token');
    expect(client.talkCalls, 0);
    expect(client.accountCalls, 1);
  });

  test('does not fall back when the user cancels Kakao Talk login', () async {
    final cancellation = Object();
    final client = _FakeKakaoClient(
      talkInstalled: true,
      talkError: cancellation,
      cancellation: cancellation,
    );

    await expectLater(
      KakaoSignInService(client: client).signInAndGetAccessToken(),
      throwsA(isA<SocialLoginCancelledException>()),
    );
    expect(client.accountCalls, 0);
  });

  test('rejects an empty OAuth access token', () async {
    final client = _FakeKakaoClient(talkInstalled: false, accountToken: '');

    await expectLater(
      KakaoSignInService(client: client).signInAndGetAccessToken(),
      throwsStateError,
    );
  });
}

class _FakeKakaoClient implements KakaoLoginClient {
  _FakeKakaoClient({
    required this.talkInstalled,
    this.talkError,
    this.cancellation,
    this.accountToken = 'account-access-token',
  });

  final bool talkInstalled;
  final Object? talkError;
  final Object? cancellation;
  final String accountToken;
  int talkCalls = 0;
  int accountCalls = 0;

  @override
  Future<bool> isTalkInstalled() async => talkInstalled;

  @override
  Future<String> loginWithTalk() async {
    talkCalls += 1;
    if (talkError case final error?) throw error;
    return 'talk-access-token';
  }

  @override
  Future<String> loginWithAccount() async {
    accountCalls += 1;
    return accountToken;
  }

  @override
  bool isCancellation(Object error) => identical(error, cancellation);
}
