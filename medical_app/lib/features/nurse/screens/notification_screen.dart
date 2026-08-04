import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/notification_mock.dart';
import '../models/notification.dart';

/// 알림 목록. 안읽은 알림은 왼쪽에 색점 표시, 누르면 읽음처리.
/// TODO: 실제 연결 시 mockNotifications() 대신 API/WebSocket으로 교체.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final List<AppNotification> _notifications = mockNotifications();

  void _markRead(AppNotification n) {
    setState(() => n.isRead = true);
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.appointment => Icons.schedule,
        NotificationType.chat => Icons.chat_bubble_outline,
        NotificationType.triage => Icons.priority_high,
        NotificationType.caseReview => Icons.fact_check_outlined,
      };

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: _notifications.isEmpty
          ? const Center(child: Text('알림이 없어요'))
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return ListTile(
                  leading: Icon(_iconFor(n.type), color: AppTheme.seed),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(n.message),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeAgo(n.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      if (!n.isRead) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => _markRead(n),
                );
              },
            ),
    );
  }
}