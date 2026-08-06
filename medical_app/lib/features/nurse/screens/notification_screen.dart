import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/communication_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../models/notification.dart';

/// 알림 목록. 실제 API(GET /api/communication/notifications/) 연동됨.
/// 안읽은 알림은 왼쪽에 색점 표시, 누르면 읽음처리(POST .../read/).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification>? _notifications;
  String? _errorMessage;
  bool _isLoading = true;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
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
      child: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = notifications[index];
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
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (!n.isRead) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
