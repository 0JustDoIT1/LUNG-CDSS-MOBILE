import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../api/communication_api.dart';
import '../auth/session_controller.dart';
import 'chat_room_screen.dart';

/// 새 대화 시작 — 같은 과 상대(의사/간호사) 목록에서 골라 채팅방으로 이동.
/// GET .../threads/counterparts/로 목록 조회, POST .../threads/start/로 대화 생성(이미 있으면 기존 스레드 반환).
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<ChatCounterpart>? _counterparts;
  String? _errorMessage;
  bool _isLoading = true;
  String? _startingUserId; // 대화 시작 요청 중인 상대(중복 탭 방지 + 로딩 표시)

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
      final counterparts = await fetchChatCounterparts(token);
      if (!mounted) return;
      setState(() {
        _counterparts = counterparts;
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

  Future<void> _startChat(ChatCounterpart counterpart) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null || _startingUserId != null) return;

    setState(() => _startingUserId = counterpart.id);
    try {
      final thread = await startChatThread(userId: counterpart.id, accessToken: token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatRoomScreen(thread: thread)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _startingUserId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 대화 시작')),
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
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final counterparts = _counterparts ?? [];
    if (counterparts.isEmpty) {
      return const Center(child: Text('대화를 시작할 수 있는 상대가 없어요'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: counterparts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final counterpart = counterparts[index];
        final isStarting = _startingUserId == counterpart.id;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              counterpart.name.isNotEmpty ? counterpart.name.substring(0, 1) : '?',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          title: Text(counterpart.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: isStarting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isStarting ? null : () => _startChat(counterpart),
        );
      },
    );
  }
}
