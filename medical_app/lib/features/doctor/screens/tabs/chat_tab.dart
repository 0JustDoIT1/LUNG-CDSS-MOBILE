import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/communication_api.dart' as api;
import '../../../../core/auth/session_controller.dart';
import '../../../../core/chat/chat_room_screen.dart';
import '../../../../core/chat/new_chat_screen.dart';
import '../../../../core/lifecycle/app_resume_notifier.dart';
import '../../../../main.dart';

/// 탭 4: 의사 채팅 목록. 실제 API(GET /api/communication/threads/) 연동됨.
/// 채팅방 안 메시지 조회/전송도 실제 API+WS 연동됨.
/// 목록은 포그라운드 푸시 수신 + 앱 재개(resume) 시 새로고침으로 최신 상태 유지.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<api.ChatThread>? _threads;
  String? _errorMessage;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    fcmService.incomingMessage.addListener(_silentRefresh);
    appResumeNotifier.addListener(_silentRefresh);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    fcmService.incomingMessage.removeListener(_silentRefresh);
    appResumeNotifier.removeListener(_silentRefresh);
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
    final allThreads = _threads ?? [];
    final totalUnread = allThreads.fold<int>(0, (sum, t) => sum + t.unreadCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            /// 🎨 상단 메디컬 타이틀 헤더
            _ChatHeader(
              totalThreads: allThreads.length,
              totalUnread: totalUnread,
            ),
            Expanded(child: _buildBody(allThreads)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: const Color(0xFF2B78D4),
        elevation: 3,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
        label: const Text(
          '새 대화',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<api.ChatThread> allThreads) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2B78D4)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B78D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (allThreads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2B78D4).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: Color(0xFF2B78D4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '대화 중인 채팅이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '우측 하단 버튼을 눌러 새 대화를 시작해보세요',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final filteredThreads = _searchQuery.isEmpty
        ? allThreads
        : allThreads
            .where((t) => t.otherParticipantName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        /// 🔍 검색 바
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: '이름으로 검색',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2B78D4)),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade400),
                      onPressed: _searchController.clear,
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2B78D4), width: 1.5),
              ),
            ),
          ),
        ),

        /// 📜 대화 목록 영역
        Expanded(
          child: filteredThreads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        '‘$_searchQuery’ 검색 결과가 없습니다',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2B78D4),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredThreads.length,
                    itemBuilder: (context, index) => _ThreadTile(
                      thread: filteredThreads[index],
                      onReturned: _silentRefresh,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// 🎨 상단 헤더
class _ChatHeader extends StatelessWidget {
  final int totalThreads;
  final int totalUnread;

  const _ChatHeader({
    required this.totalThreads,
    required this.totalUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                '대화',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              if (totalThreads > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B78D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalThreads',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B78D4),
                    ),
                  ),
                ),
            ],
          ),
          if (totalUnread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_chat_unread_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '안읽음 $totalUnread',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 🎨 카드 스타일 대화 타일
class _ThreadTile extends StatelessWidget {
  final api.ChatThread thread;
  final VoidCallback onReturned;

  const _ThreadTile({required this.thread, required this.onReturned});

  String _timeLabel(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year && now.month == time.month && now.day == time.day;
    String two(int n) => n.toString().padLeft(2, '0');
    if (isToday) return '${two(time.hour)}:${two(time.minute)}';
    return '${time.month}.${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFF2B78D4).withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? const Color(0xFF2B78D4).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: hasUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(thread: thread),
              ),
            );
            // 채팅방에서 메시지를 읽었을 수 있으니 돌아오면 안읽음 뱃지 갱신.
            onReturned();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                /// 프로필 아바타
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B78D4).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2B78D4),
                        size: 26,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                /// 이름 + 태그 + 마지막 메시지
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            thread.otherParticipantName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '의료진',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage.isEmpty ? '새로운 대화가 시작되었습니다' : thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          color: hasUnread ? const Color(0xFF1E293B) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// 시간 + 안읽음 뱃지
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeLabel(thread.lastMessageAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        color: hasUnread ? const Color(0xFF2B78D4) : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade300,
                        size: 18,
                      ),
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