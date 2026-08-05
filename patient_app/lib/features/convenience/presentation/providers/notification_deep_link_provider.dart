import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_router.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/notification_click_source.dart';
import '../../data/notification_deep_link_coordinator.dart';

final notificationClickSourceProvider = Provider<NotificationClickSource>((
  ref,
) {
  return FirebaseNotificationClickSource();
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
