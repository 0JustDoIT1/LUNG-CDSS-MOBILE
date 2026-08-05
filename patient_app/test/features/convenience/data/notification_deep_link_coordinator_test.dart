import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/features/convenience/data/notification_click_source.dart';
import 'package:patient_app/features/convenience/data/notification_deep_link_coordinator.dart';

void main() {
  test('maps result and appointment links to existing detail routes', () async {
    final router = _router();
    final coordinator = _coordinator(router: router);

    expect(
      coordinator.handleInAppDeepLink('/results/case-id'),
      NotificationNavigationResult.navigated,
    );
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/results/case-id');
    router.go('/home');

    expect(
      coordinator.handleInAppDeepLink('/appointments/appointment-id'),
      NotificationNavigationResult.navigated,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/appointments/appointment-id',
    );
  });

  test('maps missing detail screens to existing list screens', () async {
    final router = _router();
    final coordinator = _coordinator(router: router);

    coordinator.handleInAppDeepLink('/medications/logs/log-id');
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/medication');
    router.go('/home');

    coordinator.handleInAppDeepLink('/symptoms/check-id');
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/symptom-records');
  });

  test('does not route unsupported chat or invalid links', () {
    final coordinator = _coordinator(router: _router());
    expect(
      coordinator.handleInAppDeepLink('/chat/thread-id'),
      NotificationNavigationResult.unsupported,
    );
    expect(
      coordinator.handleInAppDeepLink('/unknown/id'),
      NotificationNavigationResult.invalid,
    );
  });

  test(
    'registers the click listener once and handles initial link after auth',
    () async {
      final source = _FakeClickSource(initial: '/results/initial-id');
      final router = _router();
      final coordinator = _coordinator(router: router, source: source);

      await coordinator.start();
      await coordinator.start();
      expect(source.streamReads, 1);
      expect(router.routeInformationProvider.value.uri.path, '/home');

      expect(
        coordinator.activateAndHandlePending(),
        NotificationNavigationResult.navigated,
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        '/results/initial-id',
      );
      await coordinator.dispose();
    },
  );

  test('queues opened messages until navigation is ready', () async {
    final source = _FakeClickSource();
    final router = _router();
    final coordinator = _coordinator(router: router, source: source);
    await coordinator.start();

    source.add('/appointments/opened-id');
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/home');

    coordinator.activateAndHandlePending();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/appointments/opened-id',
    );
    await coordinator.dispose();
  });

  test('queues a protected destination while logged out', () async {
    final coordinator = _coordinator(router: _router(), accessToken: null);
    expect(
      await coordinator.handleExternalDeepLink('/results/case-id'),
      NotificationNavigationResult.pending,
    );
  });

  test('prevents pushing the current destination twice', () async {
    final router = _router();
    final coordinator = _coordinator(router: router);
    coordinator.handleInAppDeepLink('/results/case-id');
    await Future<void>.delayed(Duration.zero);
    expect(
      coordinator.handleInAppDeepLink('/results/case-id'),
      NotificationNavigationResult.duplicate,
    );
  });

  test('prevents two immediate pushes to the same destination', () async {
    final router = _router();
    final coordinator = _coordinator(router: router);

    expect(
      coordinator.handleInAppDeepLink('/results/case-id'),
      NotificationNavigationResult.navigated,
    );
    expect(
      coordinator.handleInAppDeepLink('/results/case-id'),
      NotificationNavigationResult.duplicate,
    );
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/results/case-id');
  });

  testWidgets(
    'reuses the existing shell when opening a result from a root notification',
    (tester) async {
      final router = _shellRouter();
      addTearDown(router.dispose);
      final coordinator = _coordinator(router: router);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('/notifications');
      await tester.pumpAndSettle();

      expect(
        coordinator.handleInAppDeepLink('/results/case-id'),
        NotificationNavigationResult.navigated,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/results/case-id',
      );
    },
  );
}

NotificationDeepLinkCoordinator _coordinator({
  required GoRouter router,
  _FakeClickSource? source,
  String? accessToken = 'access',
}) {
  return NotificationDeepLinkCoordinator(
    source ?? _FakeClickSource(),
    _FakeTokenStorage(accessToken),
    router,
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/results/:id', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/appointments/:id', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/medication', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/symptom-records', builder: (_, _) => const SizedBox()),
    ],
  );
}

GoRouter _shellRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (_, _, child) => child,
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/results/:id', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/appointments/:id',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/medication', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/symptom-records', builder: (_, _) => const SizedBox()),
    ],
  );
}

class _FakeClickSource implements NotificationClickSource {
  _FakeClickSource({this.initial});
  final String? initial;
  final StreamController<String?> _controller = StreamController.broadcast();
  int streamReads = 0;

  @override
  Future<String?> getInitialDeepLink() async => initial;

  @override
  Stream<String?> get openedDeepLinks {
    streamReads++;
    return _controller.stream;
  }

  void add(String? value) => _controller.add(value);
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.accessToken);
  final String? accessToken;

  @override
  Future<String?> readAccessToken() async => accessToken;
}
