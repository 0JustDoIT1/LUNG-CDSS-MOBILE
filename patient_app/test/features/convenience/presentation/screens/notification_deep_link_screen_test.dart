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
    final router = _router();
    final repository = _FakeRepository();
    final coordinator = _RecordingCoordinator(router);
    await _pump(
      tester,
      router,
      repository,
      _notification(isRead: false),
      coordinator,
    );

    await tester.tap(find.text('검사 결과 알림'));
    await tester.pumpAndSettle();

    expect(repository.readIds, ['notification-id']);
    expect(coordinator.handledLinks, ['/results/case-id']);
  });

  testWidgets('allows a read notification to navigate without another POST', (
    tester,
  ) async {
    final router = _router();
    final repository = _FakeRepository();
    final coordinator = _RecordingCoordinator(router);
    await _pump(
      tester,
      router,
      repository,
      _notification(isRead: true),
      coordinator,
    );

    await tester.tap(find.text('검사 결과 알림'));
    await tester.pumpAndSettle();

    expect(repository.readIds, isEmpty);
    expect(coordinator.handledLinks, ['/results/case-id']);
  });

  testWidgets('shows a safe message for an invalid deep link', (tester) async {
    final router = _router();
    final coordinator = _RecordingCoordinator(router);
    await _pump(
      tester,
      router,
      _FakeRepository(),
      _notification(isRead: true, deepLink: '/unknown/id'),
      coordinator,
    );

    await tester.tap(find.text('검사 결과 알림'));
    await tester.pump();

    expect(find.text('해당 알림의 화면을 열 수 없습니다.'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/notifications');
  });
}

Future<void> _pump(
  WidgetTester tester,
  GoRouter router,
  NotificationRepository repository,
  PatientNotification notification,
  NotificationDeepLinkCoordinator coordinator,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
        notificationsProvider.overrideWith((ref) async => [notification]),
        notificationDeepLinkCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
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
      builder: (_, _) => const Scaffold(body: Text('상세')),
    ),
  ],
);

PatientNotification _notification({
  required bool isRead,
  String? deepLink = '/results/case-id',
}) => PatientNotification(
  id: 'notification-id',
  category: 'case_review',
  title: '검사 결과 알림',
  body: '결과가 공개되었습니다.',
  deepLink: deepLink,
  isRead: isRead,
  createdAt: DateTime(2026, 8, 5),
);

class _FakeRepository extends NotificationRepository {
  _FakeRepository() : super(NotificationApi(ApiClient(dio: Dio())));
  final List<String> readIds = [];

  @override
  Future<void> markAsRead(String notificationId) async {
    readIds.add(notificationId);
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
