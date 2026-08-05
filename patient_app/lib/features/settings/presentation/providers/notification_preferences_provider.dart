import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/models/notification_preference.dart';
import '../../data/notification_preferences_api.dart';
import '../../data/notification_preferences_repository.dart';

final notificationPreferencesApiProvider = Provider(
  (ref) => NotificationPreferencesApi(ref.watch(apiClientProvider)),
);
final notificationPreferencesRepositoryProvider = Provider(
  (ref) => NotificationPreferencesRepository(
    ref.watch(notificationPreferencesApiProvider),
  ),
);

final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesNotifier,
      List<NotificationPreference>
    >(NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier
    extends AsyncNotifier<List<NotificationPreference>> {
  @override
  Future<List<NotificationPreference>> build() => ref
      .read(notificationPreferencesRepositoryProvider)
      .fetchNotificationPreferences();

  void applyUpdate(NotificationPreference updated) {
    final current = state.asData?.value;
    if (current == null) return;
    if (updated.category == NotificationPreferenceCategory.all) {
      state = AsyncData(
        current
            .map(
              (item) => NotificationPreference(
                category: item.category,
                enabled: updated.enabled,
              ),
            )
            .toList(growable: false),
      );
      return;
    }
    final changed = current
        .map((item) => item.category == updated.category ? updated : item)
        .toList(growable: false);
    final individualEnabled = changed
        .where((item) => item.category != NotificationPreferenceCategory.all)
        .every((item) => item.enabled);
    state = AsyncData(
      changed
          .map(
            (item) => item.category == NotificationPreferenceCategory.all
                ? NotificationPreference(
                    category: item.category,
                    enabled: individualEnabled,
                  )
                : item,
          )
          .toList(growable: false),
    );
  }
}

final notificationPreferenceUpdateProvider =
    NotifierProvider<
      NotificationPreferenceUpdateNotifier,
      Set<NotificationPreferenceCategory>
    >(NotificationPreferenceUpdateNotifier.new);

class NotificationPreferenceUpdateNotifier
    extends Notifier<Set<NotificationPreferenceCategory>> {
  @override
  Set<NotificationPreferenceCategory> build() => {};

  Future<void> update(
    NotificationPreferenceCategory category,
    bool enabled,
  ) async {
    if (state.contains(category)) return;
    state = {...state, category};
    try {
      final updated = await ref
          .read(notificationPreferencesRepositoryProvider)
          .updateNotificationPreference(category: category, enabled: enabled);
      ref.read(notificationPreferencesProvider.notifier).applyUpdate(updated);
    } finally {
      state = {...state}..remove(category);
    }
  }
}
