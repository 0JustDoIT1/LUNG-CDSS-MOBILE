import 'package:dio/dio.dart';

import '../auth/auth_session_coordinator.dart';
import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenStorage,
    this._dio,
    this._refreshDio,
    this._sessionCoordinator,
  );

  static const _refreshPath = '/api/auth/refresh/';
  static const _logoutPath = '/api/auth/logout/';
  static const _socialLoginPath = '/api/auth/patient/social-login/';
  static const _registerPath = '/api/auth/patient/register/';
  static const _guardianRegisterPath = '/api/auth/guardian/register/';
  static const _retryKey = 'authRetryAttempted';

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final Dio _refreshDio;
  final AuthSessionCoordinator _sessionCoordinator;
  Future<String>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isUnauthenticatedPath(options.uri.path)) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenStorage.readAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (_sessionCoordinator.isLoggingOut) {
      handler.next(err);
      return;
    }

    if (_mustExpireWithoutRefresh(request)) {
      await _expireSession();
      handler.next(err);
      return;
    }
    if (_isUnauthenticatedPath(request.uri.path) ||
        request.uri.path == _logoutPath) {
      handler.next(err);
      return;
    }

    try {
      final sessionGeneration = _sessionCoordinator.generation;
      final accessToken = await _refreshOnce();
      if (!_sessionCoordinator.canStoreRefreshedTokens(sessionGeneration)) {
        handler.next(err);
        return;
      }

      final retryRequest = request.copyWith(
        data: request.data is FormData
            ? (request.data as FormData).clone()
            : request.data,
        headers: <String, dynamic>{
          ...request.headers,
          'Authorization': 'Bearer $accessToken',
        },
        extra: <String, dynamic>{...request.extra, _retryKey: true},
      );
      final response = await _dio.fetch<dynamic>(retryRequest);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String> _refreshOnce() {
    final existing = _refreshFuture;
    if (existing != null) return existing;

    final refresh = _refreshTokens();
    _refreshFuture = refresh;
    refresh.then<void>(
      (_) => _clearRefreshFuture(refresh),
      onError: (Object _, StackTrace _) => _clearRefreshFuture(refresh),
    );
    return refresh;
  }

  Future<String> _refreshTokens() async {
    final generation = _sessionCoordinator.generation;
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const FormatException('Refresh token is missing.');
      }

      final response = await _refreshDio.post<dynamic>(
        _refreshPath,
        data: <String, dynamic>{'refresh': refreshToken},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Refresh response must be an object.');
      }
      final access = data['access'];
      final refresh = data['refresh'];
      if (access is! String ||
          access.isEmpty ||
          refresh is! String ||
          refresh.isEmpty) {
        throw const FormatException('Refresh response tokens are invalid.');
      }
      if (!_sessionCoordinator.canStoreRefreshedTokens(generation)) {
        throw StateError('The authentication session changed during refresh.');
      }

      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      if (!_sessionCoordinator.canStoreRefreshedTokens(generation)) {
        throw StateError('The authentication session changed during refresh.');
      }
      return access;
    } catch (_) {
      if (_sessionCoordinator.isLoggingOut) rethrow;
      await _expireSession();
      rethrow;
    }
  }

  Future<void> _expireSession() async {
    try {
      await _tokenStorage.clearAuthTokens();
    } finally {
      _sessionCoordinator.notifyExpired();
    }
  }

  bool _isUnauthenticatedPath(String path) {
    return path == _refreshPath ||
        path == _socialLoginPath ||
        path == _registerPath ||
        path == _guardianRegisterPath;
  }

  bool _mustExpireWithoutRefresh(RequestOptions request) {
    return request.uri.path == _refreshPath || request.extra[_retryKey] == true;
  }

  void _clearRefreshFuture(Future<String> refresh) {
    if (identical(_refreshFuture, refresh)) {
      _refreshFuture = null;
    }
  }
}
