import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../api/communication_api.dart' as api;
import '../auth/session_controller.dart';
import 'chat_room_screen.dart';

/// 채팅 알림 딥링크(/chat/{thread_id}) 진입점.
/// 스레드 목록에서 해당 id를 찾아 ChatRoomScreen으로 교체해서 보여준다.
class ChatDeepLinkScreen extends StatefulWidget {
  final String threadId;

  const ChatDeepLinkScreen({super.key, required this.threadId});

  @override
  State<ChatDeepLinkScreen> createState() => _ChatDeepLinkScreenState();
}

class _ChatDeepLinkScreenState extends State<ChatDeepLinkScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final threads = await api.fetchChatThreads(token);
      api.ChatThread? thread;
      for (final t in threads) {
        if (t.id == widget.threadId) {
          thread = t;
          break;
        }
      }
      if (!mounted) return;

      if (thread == null) {
        setState(() => _errorMessage = '채팅방을 찾을 수 없어요.');
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(thread: thread!)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
