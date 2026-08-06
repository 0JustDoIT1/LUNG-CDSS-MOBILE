import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/communication_api.dart' as api;
import '../../../../core/auth/session_controller.dart';
import '../../../../core/chat/chat_room_screen.dart';
import '../../../../core/chat/new_chat_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

/// 탭 4: 의사 채팅 목록. 실제 API(GET /api/communication/threads/) 연동됨.
/// 채팅방 안 메시지 조회/전송도 실제 API+WS 연동됨.
/// 목록은 10초 폴링 + 포그라운드 푸시 수신 시 즉시 새로고침으로 최신 상태 유지.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<api.ChatThread>? _threads;
  String? _errorMessage;
  bool _isLoading = true;
  Timer? _pollTimer;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
    fcmService.incomingMessage.addListener(_silentRefresh);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    fcmService.incomingMessage.removeListener(_silentRefresh);
    _searchController.dispose();
    super.dispose();
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

  /// 폴링/푸시 수신 시 배경에서 조용히 새로고침 — 실패해도 기존 목록 유지, 로딩/에러 화면 건드리지 않음.
  Future<void> _silentRefresh() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      final threads = await api.fetchChatThreads(token);
      if (!mounted) return;
      setState(() => _threads = threads);
    } on ApiException catch (_) {
      // 조용히 무시
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

    final allThreads = _threads ?? [];
    final threads = _searchQuery.isEmpty
        ? allThreads
        : allThreads
            .where((t) => t.otherParticipantName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (allThreads.isEmpty) {
      return const Center(child: Text('대화 중인 채팅이 없어요'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '상대 이름으로 검색',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _searchController.clear,
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: threads.isEmpty
              ? const Center(child: Text('검색 결과가 없어요'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) => _ThreadTile(thread: threads[index]),
                  ),
                ),
        ),
      ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(thread: thread),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                /// 프로필
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.seed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.gradientEnd,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                /// 이름 + 마지막 메시지
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.otherParticipantName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                /// 시간 + 안읽음
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timeLabel(thread.lastMessageAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline,
                      ),
                    ),

                    if (thread.unreadCount > 0) ...[
                      const SizedBox(height: 8),

                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xffEF5350),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}