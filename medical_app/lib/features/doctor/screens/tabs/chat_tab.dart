import 'package:flutter/material.dart';

import '../../mock/chat_mock.dart';
import '../../models/chat.dart';
import '../chat_room_screen.dart';

/// 탭 4: 간호사 채팅 목록.
/// TODO: 실제 연결 시 mockChatThreads() 대신 API/WebSocket으로 교체.
class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = mockChatThreads()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    if (threads.isEmpty) {
      return const Center(child: Text('대화 중인 채팅이 없어요'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final t = threads[index];
        return _ThreadTile(thread: t);
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;

  const _ThreadTile({required this.thread});

  String _timeLabel(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year && now.month == time.month && now.day == time.day;
    String two(int n) => n.toString().padLeft(2, '0');
    if (isToday) return '${two(time.hour)}:${two(time.minute)}';
    return '${time.month}.${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          thread.partnerName.substring(0, 1),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ),
      title: Text(thread.partnerName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        thread.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _timeLabel(thread.lastMessageAt),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          if (thread.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${thread.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatRoomScreen(thread: thread)),
        );
      },
    );
  }
}