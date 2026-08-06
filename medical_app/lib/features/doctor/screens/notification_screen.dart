import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/communication_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../models/notification.dart';

/// 알림 목록. 실제 API(GET /api/communication/notifications/) 연동됨.
/// 카드 형태로 표시 — 안읽은 알림은 카드 왼쪽에 색띠 표시.
/// 카드를 누르면 읽음처리(POST .../read/) 후 관련 탭으로 이동.
class NotificationScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const NotificationScreen({super.key, required this.onNavigateToTab});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification>? _notifications;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final list = await fetchNotifications(token, AppNotification.fromJson);
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() => n.isRead = true);
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await markNotificationRead(n.id, token);
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => n.isRead = false); // 실패하면 되돌리기
    }
  }

  /// 서버에 일괄읽음 API가 없어서 안읽은 것들에 개별 읽음처리를 동시에 호출.
  Future<void> _markAllRead() async {
    final unread = (_notifications ?? []).where((n) => !n.isRead).toList();
    if (unread.isEmpty || _isMarkingAll) return;

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _isMarkingAll = true);
    for (final n in unread) {
      n.isRead = true;
    }
    setState(() {});

    final results = await Future.wait(
      unread.map((n) => markNotificationRead(n.id, token).then((_) => true).catchError((_) => false)),
    );

    if (!mounted) return;
    final failedCount = results.where((ok) => !ok).length;
    setState(() => _isMarkingAll = false);
    if (failedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failedCount건은 읽음처리에 실패했어요')),
      );
    }
  }

  /// 알림 종류에 맞는 하단탭 인덱스 (검토대기/일정/홈/채팅/메뉴).
  int _tabIndexFor(NotificationType type) => switch (type) {
        NotificationType.caseReview => 0,
        NotificationType.appointment => 1,
        NotificationType.chat => 3,
        NotificationType.medication => 2,
        NotificationType.triage => 2,
      };

  void _onCardTap(AppNotification n) {
    _markRead(n);
    Navigator.of(context).pop();
    widget.onNavigateToTab(_tabIndexFor(n.type));
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.medication => Icons.medication_outlined,
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
    final hasUnread = (_notifications ?? []).any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: (hasUnread && !_isMarkingAll) ? _markAllRead : null,
            child: _isMarkingAll
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('모두 읽음'),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final notifications = _notifications ?? [];
    if (notifications.isEmpty) {
      return const Center(child: Text('알림이 없어요'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationCard(
              notification: n,
              icon: _iconFor(n.type),
              timeLabel: _timeAgo(n.createdAt),
              onTap: () => _onCardTap(n),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? AppTheme.seed.withValues(alpha: 0.06) : colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.seed.withValues(alpha: 0.12),
                child: Icon(icon, color: AppTheme.seed, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
}
