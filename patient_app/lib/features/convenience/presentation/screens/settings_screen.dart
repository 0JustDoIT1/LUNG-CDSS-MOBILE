import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../settings/data/models/notification_preference.dart';
import '../../../settings/presentation/providers/notification_preferences_provider.dart';
import '../providers/security_settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final securitySettings = ref.watch(securitySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const _SectionTitle(title: '알림 설정'),
          const SizedBox(height: 10),
          _buildNotificationSettings(),
          const SizedBox(height: 28),
          const _SectionTitle(title: '보안 설정'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: securitySettings.appLockEnabled,
                title: const Text('앱 잠금'),
                subtitle: const Text('앱 실행 시 PIN 인증을 사용합니다.'),
                secondary: const Icon(Icons.lock_outline_rounded),
                onChanged: (value) {
                  ref
                      .read(securitySettingsProvider.notifier)
                      .setAppLockEnabled(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: securitySettings.biometricEnabled,
                title: const Text('생체인증 사용'),
                subtitle: const Text('지문 또는 얼굴 인증으로 잠금을 해제합니다.'),
                secondary: const Icon(Icons.fingerprint_rounded),
                onChanged: securitySettings.appLockEnabled
                    ? (value) {
                        ref
                            .read(securitySettingsProvider.notifier)
                            .setBiometricEnabled(value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle(title: '앱 정보'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('앱 버전'),
                trailing: Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('이용약관'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이용약관 화면을 준비 중입니다.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('개인정보 처리방침 화면을 준비 중입니다.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final preferences = ref.watch(notificationPreferencesProvider);
    return preferences.when(
      loading: () => const _NotificationSettingsLoading(),
      error: (error, stackTrace) => _NotificationSettingsError(
        message: _notificationErrorMessage(error, loading: true),
        onRetry: () => ref.invalidate(notificationPreferencesProvider),
      ),
      data: (items) {
        final values = {for (final item in items) item.category: item.enabled};
        final saving = ref.watch(notificationPreferenceUpdateProvider);
        const categories = NotificationPreferenceCategory.values;
        return _SettingsCard(
          children: [
            for (var index = 0; index < categories.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _notificationTile(
                category: categories[index],
                value: values[categories[index]]!,
                isSaving: saving.contains(categories[index]),
                disableAll: saving.contains(NotificationPreferenceCategory.all),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _notificationTile({
    required NotificationPreferenceCategory category,
    required bool value,
    required bool isSaving,
    required bool disableAll,
  }) {
    final presentation = _notificationPresentation(category);
    return SwitchListTile(
      value: value,
      title: Text(presentation.title),
      subtitle: Text(presentation.description),
      secondary: isSaving
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(presentation.icon),
      onChanged: isSaving || disableAll
          ? null
          : (enabled) async {
              try {
                await ref
                    .read(notificationPreferenceUpdateProvider.notifier)
                    .update(category, enabled);
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_notificationErrorMessage(error))),
                );
              }
            },
    );
  }
}

({String title, String description, IconData icon}) _notificationPresentation(
  NotificationPreferenceCategory category,
) {
  return switch (category) {
    NotificationPreferenceCategory.all => (
      title: '전체 알림',
      description: '숨잇의 주요 알림을 받습니다.',
      icon: Icons.notifications_outlined,
    ),
    NotificationPreferenceCategory.medication => (
      title: '복약 알림',
      description: '등록된 약의 복용 시간을 알려드립니다.',
      icon: Icons.medication_outlined,
    ),
    NotificationPreferenceCategory.appointment => (
      title: '진료 예약 알림',
      description: '예약된 진료 일정을 알려드립니다.',
      icon: Icons.calendar_month_outlined,
    ),
    NotificationPreferenceCategory.chat => (
      title: '채팅 알림',
      description: '새로운 채팅 메시지를 알려드립니다.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    NotificationPreferenceCategory.triage => (
      title: '증상·위험 알림',
      description: '증상 확인과 위험 관련 안내를 받습니다.',
      icon: Icons.health_and_safety_outlined,
    ),
    NotificationPreferenceCategory.caseReview => (
      title: '검사결과 알림',
      description: '검사결과 공개와 관련된 안내를 받습니다.',
      icon: Icons.assignment_outlined,
    ),
  };
}

String _notificationErrorMessage(Object error, {bool loading = false}) {
  if (error is FormatException) return '알림 설정 형식을 확인할 수 없습니다.';
  if (error is ApiException) {
    if (error.statusCode == 400) return '알림 설정을 확인해 주세요.';
    if (error.statusCode == 401) return '인증 정보가 만료됐거나 유효하지 않습니다.';
    if (error.statusCode == 403) return '알림 설정을 변경할 권한이 없습니다.';
    if (error.code == 'TIMEOUT') return '요청 시간이 초과되었습니다.';
    if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해 주세요.';
  }
  return loading ? '알림 설정을 불러오지 못했습니다.' : '알림 설정을 저장하지 못했습니다.';
}

class _NotificationSettingsLoading extends StatelessWidget {
  const _NotificationSettingsLoading();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      children: [
        SizedBox(
          height: 88,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
    );
  }
}

class _NotificationSettingsError extends StatelessWidget {
  const _NotificationSettingsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}
