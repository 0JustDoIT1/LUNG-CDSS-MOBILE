import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/settings/data/models/notification_preference.dart';
import 'package:patient_app/features/settings/data/notification_preferences_api.dart';
import 'package:patient_app/features/settings/data/notification_preferences_repository.dart';
import 'package:patient_app/features/settings/presentation/providers/notification_preferences_provider.dart';

void main() {
  test('loads data and exposes a loading state first', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(container.read(notificationPreferencesProvider).isLoading, isTrue);
    final values = await container.read(notificationPreferencesProvider.future);
    expect(values, hasLength(6));
  });

  test(
    'individual success updates only that item and recalculates all',
    () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(notificationPreferencesProvider.future);

      await container
          .read(notificationPreferenceUpdateProvider.notifier)
          .update(NotificationPreferenceCategory.chat, false);

      final values = container
          .read(notificationPreferencesProvider)
          .requireValue;
      expect(_enabled(values, NotificationPreferenceCategory.chat), isFalse);
      expect(_enabled(values, NotificationPreferenceCategory.all), isFalse);
      expect(
        _enabled(values, NotificationPreferenceCategory.medication),
        isTrue,
      );
    },
  );

  test(
    'all success updates all five individual categories with one call',
    () async {
      final repository = _FakeRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(notificationPreferencesProvider.future);

      await container
          .read(notificationPreferenceUpdateProvider.notifier)
          .update(NotificationPreferenceCategory.all, false);

      final values = container
          .read(notificationPreferencesProvider)
          .requireValue;
      expect(values.every((item) => !item.enabled), isTrue);
      expect(repository.updateCalls, 1);
    },
  );

  test(
    'all becomes true after the last disabled individual is enabled',
    () async {
      final repository = _FakeRepository(initial: _preferences(chat: false));
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(notificationPreferencesProvider.future);

      await container
          .read(notificationPreferenceUpdateProvider.notifier)
          .update(NotificationPreferenceCategory.chat, true);

      expect(
        _enabled(
          container.read(notificationPreferencesProvider).requireValue,
          NotificationPreferenceCategory.all,
        ),
        isTrue,
      );
    },
  );

  test('failure keeps the previous values', () async {
    final repository = _FakeRepository(failUpdates: true);
    final container = _container(repository);
    addTearDown(container.dispose);
    final before = await container.read(notificationPreferencesProvider.future);

    await expectLater(
      container
          .read(notificationPreferenceUpdateProvider.notifier)
          .update(NotificationPreferenceCategory.chat, false),
      throwsStateError,
    );

    expect(
      container.read(notificationPreferencesProvider).requireValue,
      same(before),
    );
  });

  test('blocks a duplicate request for the same category', () async {
    final completer = Completer<void>();
    final repository = _FakeRepository(updateGate: completer.future);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(notificationPreferencesProvider.future);
    final notifier = container.read(
      notificationPreferenceUpdateProvider.notifier,
    );

    final first = notifier.update(NotificationPreferenceCategory.chat, false);
    await Future<void>.delayed(Duration.zero);
    await notifier.update(NotificationPreferenceCategory.chat, true);
    expect(repository.updateCalls, 1);

    completer.complete();
    await first;
  });
}

ProviderContainer _container(NotificationPreferencesRepository repository) {
  final container = ProviderContainer(
    overrides: [
      notificationPreferencesRepositoryProvider.overrideWithValue(repository),
    ],
  );
  container.listen(notificationPreferencesProvider, (_, _) {});
  return container;
}

bool _enabled(
  List<NotificationPreference> values,
  NotificationPreferenceCategory category,
) => values.singleWhere((item) => item.category == category).enabled;

List<NotificationPreference> _preferences({bool chat = true}) => [
  NotificationPreference(
    category: NotificationPreferenceCategory.all,
    enabled: chat,
  ),
  const NotificationPreference(
    category: NotificationPreferenceCategory.medication,
    enabled: true,
  ),
  const NotificationPreference(
    category: NotificationPreferenceCategory.appointment,
    enabled: true,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.chat,
    enabled: chat,
  ),
  const NotificationPreference(
    category: NotificationPreferenceCategory.triage,
    enabled: true,
  ),
  const NotificationPreference(
    category: NotificationPreferenceCategory.caseReview,
    enabled: true,
  ),
];

class _FakeRepository extends NotificationPreferencesRepository {
  _FakeRepository({
    List<NotificationPreference>? initial,
    this.failUpdates = false,
    this.updateGate,
  }) : initial = initial ?? _preferences(),
       super(NotificationPreferencesApi(ApiClient(dio: Dio())));

  final List<NotificationPreference> initial;
  final bool failUpdates;
  final Future<void>? updateGate;
  int updateCalls = 0;

  @override
  Future<List<NotificationPreference>> fetchNotificationPreferences() async =>
      initial;

  @override
  Future<NotificationPreference> updateNotificationPreference({
    required NotificationPreferenceCategory category,
    required bool enabled,
  }) async {
    updateCalls++;
    if (updateGate != null) await updateGate;
    if (failUpdates) throw StateError('failed');
    return NotificationPreference(category: category, enabled: enabled);
  }
}
