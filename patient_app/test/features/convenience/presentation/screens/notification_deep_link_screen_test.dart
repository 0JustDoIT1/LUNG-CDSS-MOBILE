import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/convenience/data/models/patient_notification.dart';
import 'package:patient_app/features/convenience/data/notification_api.dart';
import 'package:patient_app/features/convenience/data/notification_click_source.dart';
import 'package:patient_app/features/convenience/data/notification_deep_link_coordinator.dart';
import 'package:patient_app/features/convenience/data/notification_repository.dart';
import 'package:patient_app/features/convenience/presentation/providers/notification_deep_link_provider.dart';
import 'package:patient_app/features/convenience/presentation/providers/notification_provider.dart';
import 'package:patient_app/features/convenience/presentation/screens/notification_list_screen.dart';

void main() {
  testWidgets('marks an unread notification and opens its valid deep link', (
    tester,
  ) async {
    final fixture = await _pump(tester, _notification(isRead: false));

    await tester.tap(find.text('notification-title'));
    await tester.pumpAndSettle();

    expect(fixture.repository.readIds, ['notification-id']);
    expect(fixture.coordinator.handledLinks, ['/results/case-id']);
  });

  testWidgets('allows a read notification to navigate without another POST', (
    tester,
  ) async {
    final fixture = await _pump(tester, _notification(isRead: true));

    await tester.tap(find.text('notification-title'));
    await tester.pumpAndSettle();

    expect(fixture.repository.readIds, isEmpty);
    expect(fixture.coordinator.handledLinks, ['/results/case-id']);
  });

  testWidgets('navigates before unread mark-as-read completes', (tester) async {
    final repository = _FakeRepository(delayRead: true);
    final fixture = await _pump(
      tester,
      _notification(isRead: false),
      repository: repository,
    );

    await tester.tap(find.text('notification-title'));
    await tester.pump();

    expect(repository.readIds, ['notification-id']);
    expect(fixture.coordinator.handledLinks, ['/results/case-id']);
    repository.completeRead();
    await tester.pumpAndSettle();
  });

  testWidgets('still navigates when mark-as-read fails', (tester) async {
    final repository = _FakeRepository(readError: StateError('failed'));
    final fixture = await _pump(
      tester,
      _notification(isRead: false),
      repository: repository,
    );

    await tester.tap(find.text('notification-title'));
    await tester.pumpAndSettle();

    expect(repository.readIds, ['notification-id']);
    expect(fixture.coordinator.handledLinks, ['/results/case-id']);
  });

  testWidgets('shows a safe message for an invalid deep link', (tester) async {
    final fixture = await _pump(
      tester,
      _notification(isRead: true, deepLink: '/unknown/id'),
    );

    await tester.tap(find.text('notification-title'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      fixture.router.routeInformationProvider.value.uri.path,
      '/notifications',
    );
  });
}

Future<
  ({
    GoRouter router,
    _FakeRepository repository,
    _RecordingCoordinator coordinator,
  })
>
_pump(
  WidgetTester tester,
  PatientNotification notification, {
  _FakeRepository? repository,
}) async {
  final router = _router();
  final resolvedRepository = repository ?? _FakeRepository();
  final coordinator = _RecordingCoordinator(router);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(resolvedRepository),
        notificationsProvider.overrideWith((ref) async => [notification]),
        notificationDeepLinkCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (
    router: router,
    repository: resolvedRepository,
    coordinator: coordinator,
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/notifications',
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const NotificationListScreen(),
    ),
    GoRoute(
      path: '/results/:id',
      builder: (_, _) => const Scaffold(body: Text('detail')),
    ),
  ],
);

PatientNotification _notification({
  required bool isRead,
  String? deepLink = '/results/case-id',
}) => PatientNotification(
  id: 'notification-id',
  category: 'case_review',
  title: 'notification-title',
  body: 'notification-body',
  deepLink: deepLink,
  isRead: isRead,
  createdAt: DateTime(2026, 8, 5),
);

class _FakeRepository extends NotificationRepository {
  _FakeRepository({this.delayRead = false, this.readError})
    : super(NotificationApi(ApiClient(dio: Dio())));

  final bool delayRead;
  final Object? readError;
  final Completer<void> _readCompleter = Completer<void>();
  final List<String> readIds = [];

  void completeRead() {
    if (!_readCompleter.isCompleted) _readCompleter.complete();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    readIds.add(notificationId);
    if (delayRead) await _readCompleter.future;
    if (readError case final error?) throw error;
  }
}

class _EmptyClickSource implements NotificationClickSource {
  @override
  Future<String?> getInitialDeepLink() async => null;

  @override
  Stream<String?> get openedDeepLinks => const Stream<String?>.empty();
}

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'access';
}

class _RecordingCoordinator extends NotificationDeepLinkCoordinator {
  _RecordingCoordinator(GoRouter router)
    : super(_EmptyClickSource(), _FakeTokenStorage(), router);

  final List<String?> handledLinks = [];

  @override
  NotificationNavigationResult handleInAppDeepLink(String? deepLink) {
    handledLinks.add(deepLink);
    if (deepLink == '/results/case-id') {
      return NotificationNavigationResult.navigated;
    }
    return NotificationNavigationResult.invalid;
  }
}
