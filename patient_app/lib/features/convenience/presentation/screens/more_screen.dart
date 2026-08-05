import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('더보기'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이대박',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '환자번호 2026080301',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MoreMenuTile(
            icon: Icons.person_outline_rounded,
            title: '내 정보',
            onTap: () {
              context.push(RouteNames.profile);
            },
          ),

          _MoreMenuTile(
            icon: Icons.family_restroom_outlined,
            title: '보호자 연동',
            onTap: () {
              context.push(RouteNames.guardianLink);
            },
          ),
          _MoreMenuTile(
            icon: Icons.qr_code_rounded,
            title: '진료카드 QR',
            onTap: () {
              context.push(RouteNames.patientQr);
            },
          ),
          _MoreMenuTile(
            icon: Icons.notifications_none_rounded,
            title: '알림',
            onTap: () {
              context.push(RouteNames.notifications);
            },
          ),
          _MoreMenuTile(
            icon: Icons.settings_outlined,
            title: '설정',
            onTap: () {
              context.push(RouteNames.settings);
            },
          ),
          const SizedBox(height: 16),
          _MoreMenuTile(
            icon: Icons.logout_rounded,
            title: '로그아웃',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              final shouldSignOut = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text(
                      '숨잇에서 로그아웃하시겠습니까?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('로그아웃'),
                      ),
                    ],
                  );
                },
              );

              if (shouldSignOut != true || !context.mounted) {
                return;
              }

              await ref
                  .read(authProvider.notifier)
                  .signOut();

              if (!context.mounted) {
                return;
              }

              context.go(RouteNames.login);
            },
          ),
        ],
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
      ),
    );
  }
}