import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/convenience/presentation/screens/settings_screen.dart';
import 'package:patient_app/features/settings/data/models/notification_preference.dart';
import 'package:patient_app/features/settings/data/notification_preferences_api.dart';
import 'package:patient_app/features/settings/data/notification_preferences_repository.dart';
import 'package:patient_app/features/settings/presentation/providers/notification_preferences_provider.dart';

void main() {
  testWidgets('shows all six server-backed notification settings', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    for (final title in <String>[
      '전체 알림',
      '복약 알림',
      '진료 예약 알림',
      '채팅 알림',
      '증상·위험 알림',
      '검사결과 알림',
    ]) {
      expect(find.text(title), findsOneWidget);
    }

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.take(6).map((item) => item.value), <bool>[
      false,
      true,
      true,
      false,
      true,
      true,
    ]);
  });

  testWidgets('shows an error without inventing toggle values and retries', (
    tester,
  ) async {
    final repository = _FakeRepository(loadFailures: 1);
    await _pump(tester, repository);

    expect(find.text('알림 설정을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('전체 알림'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('전체 알림'), findsOneWidget);
  });

  testWidgets('patches one category when its switch is changed', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(find.byType(Switch).at(3));
    await tester.pumpAndSettle();

    expect(repository.updatedCategories, [NotificationPreferenceCategory.chat]);
    expect(repository.updatedValues, [true]);
  });
}

Future<void> _pump(
  WidgetTester tester,
  NotificationPreferencesRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeRepository extends NotificationPreferencesRepository {
  _FakeRepository({this.loadFailures = 0})
    : super(NotificationPreferencesApi(ApiClient(dio: Dio())));

  final int loadFailures;
  int loadCalls = 0;
  final List<NotificationPreferenceCategory> updatedCategories = [];
  final List<bool> updatedValues = [];

  @override
  Future<List<NotificationPreference>> fetchNotificationPreferences() async {
    loadCalls++;
    if (loadCalls <= loadFailures) throw StateError('failed');
    return _preferences;
  }

  @override
  Future<NotificationPreference> updateNotificationPreference({
    required NotificationPreferenceCategory category,
    required bool enabled,
  }) async {
    updatedCategories.add(category);
    updatedValues.add(enabled);
    return NotificationPreference(category: category, enabled: enabled);
  }
}

const _preferences = <NotificationPreference>[
  NotificationPreference(
    category: NotificationPreferenceCategory.all,
    enabled: false,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.medication,
    enabled: true,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.appointment,
    enabled: true,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.chat,
    enabled: false,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.triage,
    enabled: true,
  ),
  NotificationPreference(
    category: NotificationPreferenceCategory.caseReview,
    enabled: true,
  ),
];
