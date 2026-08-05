import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_router.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/notification_click_source.dart';
import '../../data/notification_deep_link_coordinator.dart';
import '../../data/notification_display_service.dart';

final notificationDisplayServiceProvider = Provider<NotificationDisplayService>(
  (ref) {
    final service = NotificationDisplayService();
    ref.onDispose(() => unawaited(service.dispose()));
    return service;
  },
);

final notificationClickSourceProvider = Provider<NotificationClickSource>((
  ref,
) {
  return FirebaseNotificationClickSource(
    null,
    ref.watch(notificationDisplayServiceProvider),
  );
});

final notificationDeepLinkCoordinatorProvider =
    Provider<NotificationDeepLinkCoordinator>((ref) {
      final coordinator = NotificationDeepLinkCoordinator(
        ref.watch(notificationClickSourceProvider),
        ref.watch(tokenStorageProvider),
        appRouter,
      );
      ref.onDispose(() => unawaited(coordinator.dispose()));
      return coordinator;
    });
