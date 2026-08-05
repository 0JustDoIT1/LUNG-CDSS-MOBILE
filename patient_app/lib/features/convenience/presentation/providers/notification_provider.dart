import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/models/patient_notification.dart';
import '../../data/notification_api.dart';
import '../../data/notification_repository.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return NotificationApi(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final notificationApi = ref.watch(notificationApiProvider);

  return NotificationRepository(notificationApi);
});

final notificationsProvider = FutureProvider<List<PatientNotification>>((
  ref,
) async {
  final repository = ref.read(notificationRepositoryProvider);

  return repository.getNotifications();
});

final notificationReadProvider =
    NotifierProvider<NotificationReadNotifier, Set<String>>(
      NotificationReadNotifier.new,
    );

class NotificationReadNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return <String>{};
  }

  Future<void> markAsRead(String notificationId) async {
    if (state.contains(notificationId)) {
      return;
    }

    state = <String>{...state, notificationId};

    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notificationId);
      ref.invalidate(notificationsProvider);
    } finally {
      state = <String>{...state}..remove(notificationId);
    }
  }
}
