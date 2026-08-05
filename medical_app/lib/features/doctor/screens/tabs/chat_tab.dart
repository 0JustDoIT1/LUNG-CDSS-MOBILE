import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/communication_api.dart' as api;
import '../../../../core/auth/session_controller.dart';
import '../../../../core/chat/chat_room_screen.dart';
import '../../../../core/chat/new_chat_screen.dart';

/// 탭 4: 의사 채팅 목록. 실제 API(GET /api/communication/threads/) 연동됨.
/// 채팅방 안 메시지 조회/전송도 실제 API+WS 연동됨.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<api.ChatThread>? _threads;
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
      final threads = await api.fetchChatThreads(token);
      if (!mounted) return;
      setState(() {
        _threads = threads;
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

  Future<void> _startNewChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewChatScreen()),
    );
    _load(); // 새 대화가 생겼을 수 있으니 목록 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        tooltip: '새 대화 시작',
        child: const Icon(Icons.add_comment_outlined),
      ),
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
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final threads = _threads ?? [];
    if (threads.isEmpty) {
      return const Center(child: Text('대화 중인 채팅이 없어요'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
        itemBuilder: (context, index) => _ThreadTile(thread: threads[index]),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final api.ChatThread thread;

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
          thread.otherParticipantName.isNotEmpty ? thread.otherParticipantName.substring(0, 1) : '?',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
        ),
      ),
      title: Text(thread.otherParticipantName, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            _timeLabel(thread.createdAt),
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