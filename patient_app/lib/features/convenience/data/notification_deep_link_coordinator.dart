import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../../app/routes/route_names.dart';
import '../../../core/auth/token_storage.dart';
import 'models/notification_destination.dart';
import 'notification_click_source.dart';

enum NotificationNavigationResult {
  navigated,
  pending,
  invalid,
  unsupported,
  duplicate,
}

class NotificationDeepLinkCoordinator {
  NotificationDeepLinkCoordinator(
    this._clickSource,
    this._tokenStorage,
    this._router,
  );

  final NotificationClickSource _clickSource;
  final TokenStorage _tokenStorage;
  final GoRouter _router;

  StreamSubscription<String?>? _openedSubscription;
  NotificationDestination? _pendingDestination;
  bool _navigationReady = false;
  String? _navigationInProgressLocation;

  Future<void> start() async {
    if (_openedSubscription != null) return;
    _openedSubscription = _clickSource.openedDeepLinks.listen(
      (deepLink) => unawaited(handleExternalDeepLink(deepLink)),
      onError: (_) {},
    );
    try {
      final initialDeepLink = await _clickSource.getInitialDeepLink();
      if (initialDeepLink != null) {
        await handleExternalDeepLink(initialDeepLink);
      }
    } catch (_) {
      return;
    }
  }

  Future<NotificationNavigationResult> handleExternalDeepLink(
    String? deepLink,
  ) async {
    final destination = NotificationDeepLinkParser.parse(deepLink);
    if (destination == null) return NotificationNavigationResult.invalid;
    if (destination.type == NotificationDestinationType.chat) {
      return NotificationNavigationResult.unsupported;
    }

    final accessToken = await _tokenStorage.readAccessToken();
    if (!_navigationReady || accessToken == null || accessToken.isEmpty) {
      _pendingDestination = destination;
      return NotificationNavigationResult.pending;
    }
    return _navigate(destination);
  }

  NotificationNavigationResult handleInAppDeepLink(String? deepLink) {
    final destination = NotificationDeepLinkParser.parse(deepLink);
    if (destination == null) return NotificationNavigationResult.invalid;
    if (destination.type == NotificationDestinationType.chat) {
      return NotificationNavigationResult.unsupported;
    }
    return _navigate(destination);
  }

  NotificationNavigationResult activateAndHandlePending() {
    _navigationReady = true;
    final pending = _pendingDestination;
    _pendingDestination = null;
    if (pending == null) return NotificationNavigationResult.invalid;
    return _navigate(pending, replace: true);
  }

  void deactivate() {
    _navigationReady = false;
  }

  NotificationNavigationResult _navigate(
    NotificationDestination destination, {
    bool replace = false,
  }) {
    final location = switch (destination.type) {
      NotificationDestinationType.result =>
        RouteNames.resultDetail.replaceFirst(
          ':resultId',
          Uri.encodeComponent(destination.id),
        ),
      NotificationDestinationType.appointment =>
        '${RouteNames.appointments}/${Uri.encodeComponent(destination.id)}',
      NotificationDestinationType.medication => RouteNames.medication,
      NotificationDestinationType.symptom => RouteNames.symptomRecordList,
      NotificationDestinationType.chat => throw StateError('지원하지 않는 이동 대상입니다.'),
    };

    final currentLocation = _router.routeInformationProvider.value.uri
        .toString();
    if (currentLocation == location ||
        _navigationInProgressLocation == location) {
      return NotificationNavigationResult.duplicate;
    }
    if (replace || _isShellDestination(destination)) {
      // Pushing a second location that contains the same ShellRoute keeps the
      // existing shell in the root stack and mounts its Navigator key twice.
      // Switching locations keeps one shell instance and preserves its tabs.
      _router.go(location);
    } else {
      _navigationInProgressLocation = location;
      unawaited(
        _router
            .push<void>(location)
            .then<void>(
              (_) => _clearNavigationInProgress(location),
              onError: (Object _, StackTrace _) {
                _clearNavigationInProgress(location);
              },
            ),
      );
    }
    return NotificationNavigationResult.navigated;
  }

  bool _isShellDestination(NotificationDestination destination) {
    return destination.type == NotificationDestinationType.result ||
        destination.type == NotificationDestinationType.appointment;
  }

  void _clearNavigationInProgress(String location) {
    if (_navigationInProgressLocation == location) {
      _navigationInProgressLocation = null;
    }
  }

  Future<void> dispose() async {
    await _openedSubscription?.cancel();
    _openedSubscription = null;
  }
}
