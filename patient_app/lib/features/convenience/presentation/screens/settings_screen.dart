import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

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
                value: securitySettings.value?.appLockEnabled ?? false,
                title: const Text('앱 잠금'),
                subtitle: const Text('앱 실행 시 PIN 인증을 사용합니다.'),
                secondary: const Icon(Icons.lock_outline_rounded),
                onChanged: (value) => _changeAppLock(value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: securitySettings.value?.biometricEnabled ?? false,
                title: const Text('생체인증 사용'),
                subtitle: const Text('지문 또는 얼굴 인증으로 잠금을 해제합니다.'),
                secondary: const Icon(Icons.fingerprint_rounded),
                onChanged: (securitySettings.value?.appLockEnabled ?? false)
                    ? (value) async {
                        final saved = await ref
                            .read(securitySettingsProvider.notifier)
                            .setBiometricEnabled(value);
                        if (!saved && mounted) {
                          _showMessage('생체인증 설정을 저장하지 못했습니다.');
                        }
                      }
                    : null,
              ),
              if (securitySettings.value?.appLockEnabled ?? false) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('PIN 변경'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _changePin,
                ),
              ],
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

  Future<void> _changeAppLock(bool enabled) async {
    if (enabled) {
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const _PinSetupScreen(mode: _PinSetupMode.create),
        ),
      );
      if (success != true && mounted) {
        _showMessage('PIN 설정을 취소했습니다. 앱 잠금은 켜지지 않았습니다.');
      }
      return;
    }

    final pin = await _askCurrentPin();
    if (pin == null) return;
    final disabled = await ref
        .read(securitySettingsProvider.notifier)
        .disable(pin);
    if (mounted) {
      _showMessage(disabled ? '앱 잠금을 해제했습니다.' : 'PIN 번호가 올바르지 않습니다.');
    }
  }

  Future<void> _changePin() async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const _PinSetupScreen(mode: _PinSetupMode.change),
      ),
    );
    if (success == true && mounted) _showMessage('PIN을 변경했습니다.');
  }

  Future<String?> _askCurrentPin() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('앱 잠금 해제'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '현재 PIN 4자리'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.length == 4) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

enum _PinSetupMode { create, change }

class _PinSetupScreen extends ConsumerStatefulWidget {
  const _PinSetupScreen({required this.mode});

  final _PinSetupMode mode;

  @override
  ConsumerState<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<_PinSetupScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final newPin = _newController.text;
    if (newPin.length != 4 || _confirmController.text.length != 4) {
      setState(() => _error = '4자리 숫자 PIN을 입력해주세요.');
      return;
    }
    if (newPin != _confirmController.text) {
      setState(() => _error = '새 PIN 번호가 일치하지 않습니다.');
      return;
    }
    if (widget.mode == _PinSetupMode.change &&
        _currentController.text.length != 4) {
      setState(() => _error = '현재 PIN 4자리를 입력해주세요.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(securitySettingsProvider.notifier);
    final success = widget.mode == _PinSetupMode.create
        ? await notifier.setPin(newPin)
        : await notifier.changePin(_currentController.text, newPin);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = widget.mode == _PinSetupMode.change
          ? '현재 PIN이 올바르지 않거나 변경하지 못했습니다.'
          : 'PIN을 저장하지 못했습니다. 다시 시도해주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == _PinSetupMode.create ? 'PIN 설정' : 'PIN 변경'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('앱 잠금에 사용할 4자리 숫자 PIN을 입력해주세요.'),
          const SizedBox(height: 24),
          if (widget.mode == _PinSetupMode.change) ...[
            _pinField(_currentController, '현재 PIN'),
            const SizedBox(height: 12),
          ],
          _pinField(_newController, '새 PIN'),
          const SizedBox(height: 12),
          _pinField(_confirmController, '새 PIN 확인'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}
