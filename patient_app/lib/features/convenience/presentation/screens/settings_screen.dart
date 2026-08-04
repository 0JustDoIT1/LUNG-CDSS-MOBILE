import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_settings_provider.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  ConsumerState<SettingsScreen> createState() =>
     _SettingsScreenState();
}

class _SettingsScreenState
    extends ConsumerState<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _medicationNotificationEnabled = true;
  bool _appointmentNotificationEnabled = true;


 @override
  Widget build(BuildContext context) {
    final securitySettings = ref.watch(
      securitySettingsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          const _SectionTitle(
            title: '알림 설정',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: _notificationEnabled,
                title: const Text('전체 알림'),
                subtitle: const Text(
                  '숨잇의 주요 알림을 받습니다.',
                ),
                secondary: const Icon(
                  Icons.notifications_outlined,
                ),
                onChanged: (value) {
                  setState(() {
                    _notificationEnabled = value;

                    if (!value) {
                      _medicationNotificationEnabled = false;
                      _appointmentNotificationEnabled = false;
                    }
                  });
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _medicationNotificationEnabled,
                title: const Text('복약 알림'),
                subtitle: const Text(
                  '등록된 약의 복용 시간을 알려드립니다.',
                ),
                secondary: const Icon(
                  Icons.medication_outlined,
                ),
                onChanged: _notificationEnabled
                    ? (value) {
                        setState(() {
                          _medicationNotificationEnabled =
                              value;
                        });
                      }
                    : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _appointmentNotificationEnabled,
                title: const Text('진료 예약 알림'),
                subtitle: const Text(
                  '예약된 진료 일정을 알려드립니다.',
                ),
                secondary: const Icon(
                  Icons.calendar_month_outlined,
                ),
                onChanged: _notificationEnabled
                    ? (value) {
                        setState(() {
                          _appointmentNotificationEnabled =
                              value;
                        });
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle(
            title: '보안 설정',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: securitySettings.appLockEnabled,
                title: const Text('앱 잠금'),
                subtitle: const Text(
                  '앱 실행 시 PIN 인증을 사용합니다.',
                ),
                secondary: const Icon(
                  Icons.lock_outline_rounded,
                ),
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
                subtitle: const Text(
                  '지문 또는 얼굴 인증으로 잠금을 해제합니다.',
                ),
                secondary: const Icon(
                  Icons.fingerprint_rounded,
                ),
                onChanged: securitySettings.appLockEnabled
                    ? (value) {
                        ref
                            .read(
                              securitySettingsProvider.notifier,
                            )
                            .setBiometricEnabled(value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle(
            title: '앱 정보',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                ),
                title: Text('앱 버전'),
                trailing: Text('1.0.0'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                ),
                title: const Text('이용약관'),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '이용약관 화면을 준비 중입니다.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                ),
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '개인정보 처리방침 화면을 준비 중입니다.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}