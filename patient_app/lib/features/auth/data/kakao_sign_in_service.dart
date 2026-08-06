import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class SocialLoginCancelledException implements Exception {
  const SocialLoginCancelledException();
}

class KakaoLoginConfigurationException implements Exception {
  const KakaoLoginConfigurationException();
}

class KakaoLoginFailedException implements Exception {
  const KakaoLoginFailedException();
}

abstract class KakaoLoginClient {
  Future<bool> isTalkInstalled();

  Future<String> loginWithTalk();

  Future<String> loginWithAccount();

  bool isCancellation(Object error);
}

class KakaoSdkLoginClient implements KakaoLoginClient {
  @override
  Future<bool> isTalkInstalled() => isKakaoTalkInstalled();

  @override
  Future<String> loginWithTalk() async {
    final token = await UserApi.instance.loginWithKakaoTalk();
    return token.accessToken;
  }

  @override
  Future<String> loginWithAccount() async {
    final token = await UserApi.instance.loginWithKakaoAccount();
    return token.accessToken;
  }

  @override
  bool isCancellation(Object error) {
    return (error is KakaoClientException &&
            error.reason == ClientErrorCause.cancelled) ||
        (error is KakaoAuthException &&
            error.error == AuthErrorCause.accessDenied) ||
        (error is KakaoApiException &&
            error.code == ApiErrorCause.accessDenied);
  }
}

class KakaoSignInService {
  KakaoSignInService({KakaoLoginClient? client})
      : _client = client ?? KakaoSdkLoginClient();

  final KakaoLoginClient _client;

  Future<String> signInAndGetAccessToken() async {
    if (kIsWeb) {
      throw UnsupportedError(
        '카카오 로그인은 현재 Android 앱에서만 지원합니다.',
      );
    }

    bool talkInstalled;

    try {
      talkInstalled = await _client.isTalkInstalled();

      if (kDebugMode) {
        debugPrint('[KakaoLogin] stage=isTalkInstalled success');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[KakaoLogin] stage=isTalkInstalled '
          'errorType=${error.runtimeType}',
        );
      }

      talkInstalled = false;
    }

    if (talkInstalled) {
      try {
        final token = await _client.loginWithTalk();

        if (kDebugMode) {
          debugPrint('[KakaoLogin] stage=loginWithTalk success');
        }

        return _validateToken(token);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            '[KakaoLogin] stage=loginWithTalk '
            'errorType=${error.runtimeType}',
          );
        }

        if (_client.isCancellation(error)) {
          throw const SocialLoginCancelledException();
        }
      }
    }

    try {
      final token = await _client.loginWithAccount();

      if (kDebugMode) {
        debugPrint('[KakaoLogin] stage=loginWithAccount success');
      }

      return _validateToken(token);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[KakaoLogin] stage=loginWithAccount '
          'errorType=${error.runtimeType}',
        );

        if (error is KakaoAuthException) {
          debugPrint(
            '[KakaoLogin] authError=${error.error}',
          );
        } else if (error is KakaoClientException) {
          debugPrint(
            '[KakaoLogin] clientReason=${error.reason}',
          );
        } else if (error is KakaoApiException) {
          debugPrint(
            '[KakaoLogin] apiError=${error.code}',
          );
        }
      }

      if (_client.isCancellation(error)) {
        throw const SocialLoginCancelledException();
      }

      if (error is StateError) {
        rethrow;
      }

      if (_isConfigurationError(error)) {
        throw const KakaoLoginConfigurationException();
      }

      throw const KakaoLoginFailedException();
    }
  }

  String _validateToken(String token) {
    if (token.isEmpty) {
      throw StateError(
        '카카오 로그인에서 OAuth access token을 받지 못했습니다.',
      );
    }

    return token;
  }

  bool _isConfigurationError(Object error) {
    return error is KakaoAuthException &&
        (error.error == AuthErrorCause.invalidClient ||
            error.error == AuthErrorCause.misconfigured ||
            error.error == AuthErrorCause.unauthorized);
  }
}