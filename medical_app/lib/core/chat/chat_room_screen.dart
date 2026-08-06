import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../api/communication_api.dart';
import '../auth/session_controller.dart';
import '../theme/app_theme.dart';

/// 채팅방. 의사/간호사 공용 화면 (상대가 의사든 간호사든 동일).
/// - 진입 시 GET .../messages/로 과거 히스토리 로딩
/// - 이후 WS(wss://.../ws/chat/{thread_id})로 연결해 실시간 송수신
/// - 메시지 전송은 WS로 보냄(REST로 보내면 저장은 되지만 실시간 전파가 안 됨)
/// - @멘션: 입력창 '@' 버튼으로 상대방 이름 삽입, 말풍선에서 @이름 굵게 강조
class ChatRoomScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatRoomScreen({super.key, required this.thread});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// 내가 보낸 메시지를 화면에 즉시 그려주고(낙관적 렌더링), 서버가 WS로 되돌려준 진짜
  /// 메시지가 도착하면 여기서 짝을 찾아 교체 — 안 그러면 WS 왕복 시간만큼 전송이 느리게 느껴진다.
  final List<ChatMessage> _pendingOptimistic = [];

  ChatSocket? _socket;
  String? _myUserId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _socket?.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = context.read<SessionController>();
    final token = session.accessToken;
    if (token == null) return;
    _myUserId = session.myUserId;

    try {
      final history = await fetchChatMessages(widget.thread.id, token);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _isLoading = false;
      });
      _scrollToBottom(animated: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    }

    _socket?.dispose();
    _socket = ChatSocket(
      threadId: widget.thread.id,
      accessToken: token,
      onMessage: (message) {
        if (!mounted) return;
        setState(() {
          final matchIndex = message.sender == _myUserId
              ? _pendingOptimistic.indexWhere((m) => m.content == message.content)
              : -1;
          if (matchIndex == -1) {
            _messages.add(message);
          } else {
            // 내가 낙관적으로 그려둔 메시지를 서버가 확정한 진짜 메시지로 교체.
            final optimistic = _pendingOptimistic.removeAt(matchIndex);
            final listIndex = _messages.indexOf(optimistic);
            if (listIndex == -1) {
              _messages.add(message);
            } else {
              _messages[listIndex] = message;
            }
          }
        });
        _scrollToBottom(animated: true);
      },
    )..connect();
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _insertMention() {
    final mention = '@${widget.thread.otherParticipantName} ';
    final text = _inputController.text;
    final selection = _inputController.selection;
    final insertAt = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(insertAt, insertAt, mention);
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + mention.length),
    );
  }

  void _send() {
    final text = _inputController.text.trim();
    final myId = _myUserId;
    if (text.isEmpty || myId == null) return;

    final optimistic = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      sender: myId,
      senderName: '',
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(optimistic);
      _pendingOptimistic.add(optimistic);
    });
    _scrollToBottom(animated: true);

    _inputController.clear();
    _socket?.send(text);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.otherParticipantName)),
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

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isMe = message.sender == _myUserId;
              final showDateDivider =
                  index == 0 || !_isSameDay(_messages[index - 1].createdAt, message.createdAt);
              return Column(
                children: [
                  if (showDateDivider) _DateDivider(date: message.createdAt),
                  _MessageBubble(message: message, isMe: isMe),
                ],
              );
            },
          ),
        ),
        _MessageInputBar(
          controller: _inputController,
          onSend: _send,
          onMention: _insertMention,
        ),
      ],
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final label = '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// 메시지 텍스트 안 '@이름' 부분을 굵게 강조해서 보여줌.
List<InlineSpan> _buildMentionSpans(String text, {required bool isMe}) {
  final mentionPattern = RegExp(r'@\S+');
  final spans = <InlineSpan>[];
  var lastEnd = 0;

  for (final match in mentionPattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isMe ? Colors.yellow.shade100 : AppTheme.seed,
      ),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }
  return spans;
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final timeLabel = '${two(message.createdAt.hour)}:${two(message.createdAt.minute)}';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName.substring(0, 1) : '?',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isMe) ...[
            Text(timeLabel, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.seed : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isMe ? Colors.white : colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  children: _buildMentionSpans(message.content, isMe: isMe),
                ),
              ),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 6),
            Text(timeLabel, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMention;

  const _MessageInputBar({
    required this.controller,
    required this.onSend,
    required this.onMention,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onMention,
            tooltip: '멘션',
            icon: Icon(Icons.alternate_email, color: AppTheme.seed),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '메시지 입력',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            style: IconButton.styleFrom(backgroundColor: AppTheme.seed),
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
