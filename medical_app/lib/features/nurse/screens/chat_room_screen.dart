import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/chat_mock.dart';
import '../models/chat.dart';

/// 채팅방. 메시지 전송은 지금 로컬 상태에만 추가됨(새로고침하면 초기화).
/// - @멘션: 입력창 '@' 버튼으로 상대방 이름 삽입, 말풍선에서 @이름 굵게 강조
/// - 읽음/안읽음: 내가 보낸 메시지에 '읽음'(회색) 또는 안읽음 뱃지 표시
/// TODO: 실제 연결 시 WebSocket/API로 교체 — 채널 구독, 실시간 읽음처리, 음성메시지 등.
class ChatRoomScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatRoomScreen({super.key, required this.thread});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final List<ChatMessage> _messages = mockMessagesFor(widget.thread.id);
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _insertMention() {
    final mention = '@${widget.thread.partnerName} ';
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
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        senderName: '나',
        isMe: true,
        text: text,
        sentAt: DateTime.now(),
      ));
      _inputController.clear();
    });

    // TODO: 메시지 전송 API/WebSocket 연결

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.partnerName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final showDateDivider = index == 0 ||
                    !_isSameDay(_messages[index - 1].sentAt, message.sentAt);
                return Column(
                  children: [
                    if (showDateDivider) _DateDivider(date: message.sentAt),
                    _MessageBubble(message: message),
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
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final label = '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final timeLabel = '${two(message.sentAt.hour)}:${two(message.sentAt.minute)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                message.senderName.substring(0, 1),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (message.isMe) ...[
            Text(timeLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe ? AppTheme.seed : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: message.isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  children: _buildMentionSpans(message.text, isMe: message.isMe),
                ),
              ),
            ),
          ),
          if (!message.isMe) ...[
            const SizedBox(width: 6),
            Text(timeLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
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
                fillColor: Colors.grey.shade100,
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