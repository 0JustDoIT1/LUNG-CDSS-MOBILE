import 'package:flutter/material.dart';
import '../../../../core/widgets/app_empty_view.dart';


class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({
    super.key,
  });

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends State<NotificationListScreen> {
  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      id: 'notification-001',
      type: _NotificationType.result,
      title: '검사 결과가 등록되었습니다',
      message: '최근 진행한 검사 결과를 확인할 수 있습니다.',
      dateText: '오늘 오후 2:10',
      isRead: false,
    ),
    _NotificationItem(
      id: 'notification-002',
      type: _NotificationType.appointment,
      title: '진료 예약 안내',
      message: '내일 오전 10시에 호흡기내과 진료가 예정되어 있습니다.',
      dateText: '오늘 오전 9:00',
      isRead: false,
    ),
    _NotificationItem(
      id: 'notification-003',
      type: _NotificationType.medication,
      title: '복약 시간입니다',
      message: '등록된 약을 복용한 뒤 복약 여부를 확인해주세요.',
      dateText: '어제 오후 8:00',
      isRead: true,
    ),
    _NotificationItem(
      id: 'notification-004',
      type: _NotificationType.intake,
      title: '진료 전 문진 작성 안내',
      message: '원활한 진료를 위해 방문 전 문진을 작성해주세요.',
      dateText: '어제 오전 11:30',
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _markAsRead(_NotificationItem notification) {
    if (notification.isRead) {
      return;
    }

    setState(() {
      notification.isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((notification) => !notification.isRead)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed:
                unreadCount == 0 ? null : _markAllAsRead,
            child: const Text('모두 읽음'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _notifications.isEmpty
          ? const AppEmptyView(
              icon: Icons.notifications_none_rounded,
              title: '새로운 알림이 없습니다.',
              description: '새로운 검사 결과나 예약 알림이 도착하면 이곳에서 확인할 수 있습니다.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24,
              ),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final notification =
                    _notifications[index];

                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    _markAsRead(notification);
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final _NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead
          ? Colors.white
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBackgroundColor(
                    context,
                    notification.type,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconData(notification.type),
                  color: _iconColor(
                    context,
                    notification.type,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(
                              top: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notification.dateText,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(_NotificationType type) {
    switch (type) {
      case _NotificationType.result:
        return Icons.description_outlined;
      case _NotificationType.appointment:
        return Icons.calendar_month_outlined;
      case _NotificationType.medication:
        return Icons.medication_outlined;
      case _NotificationType.intake:
        return Icons.assignment_outlined;
    }
  }

  Color _iconColor(
    BuildContext context,
    _NotificationType type,
  ) {
    switch (type) {
      case _NotificationType.result:
        return Colors.blue.shade700;
      case _NotificationType.appointment:
        return Colors.green.shade700;
      case _NotificationType.medication:
        return Colors.orange.shade700;
      case _NotificationType.intake:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _iconBackgroundColor(
    BuildContext context,
    _NotificationType type,
  ) {
    return _iconColor(
      context,
      type,
    ).withValues(alpha: 0.1);
  }
}


enum _NotificationType {
  result,
  appointment,
  medication,
  intake,
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.dateText,
    required this.isRead,
  });

  final String id;
  final _NotificationType type;
  final String title;
  final String message;
  final String dateText;
  bool isRead;
}