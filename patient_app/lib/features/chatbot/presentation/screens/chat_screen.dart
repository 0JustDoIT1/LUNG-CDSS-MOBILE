import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../data/mock/mock_chat_data.dart';
import '../../../../data/models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isListening = false;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      _messageFocusNode.requestFocus();

      await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  Future<void> _sendMessage([String? suggestedQuestion]) async {
    final content = suggestedQuestion ?? _messageController.text.trim();

    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final succeeded = await ref
        .read(chatProvider.notifier)
        .sendMessage(content);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      if (succeeded) {
        _messageController.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _retryMessage(String errorMessageId) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    await ref.read(chatProvider.notifier).retryMessage(errorMessageId);
    if (!mounted) return;
    setState(() => _isSending = false);
  }

  Future<void> _startVoiceInput() async {
    if (_isListening || _isSending) {
      return;
    }

    setState(() {
      _isListening = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
      _messageController.text = '최근 검사결과를 설명해주세요.';
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('음성 입력 내용을 텍스트로 변환했습니다.')));
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    ref.listen(chatProvider, (previous, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 챗봇'),
        actions: [
          IconButton(
            tooltip: '대화 초기화',
            onPressed: _isSending
                ? null
                : () async {
                    await ref.read(chatProvider.notifier).resetChat();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.when(
                loading: () => const AppLoadingView(message: '대화를 불러오는 중입니다.'),
                error: (error, stackTrace) => AppErrorView(
                  message: '대화를 다시 불러와주세요.',
                  onRetry: () {
                    ref.invalidate(chatProvider);
                  },
                ),
                data: (messages) {
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    children: [
                      _SuggestedQuestions(onSelected: _sendMessage),
                      const SizedBox(height: 20),
                      ...messages.map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _MessageBubble(
                            message: message,
                            onRetry: message.isError
                                ? () => _retryMessage(message.id)
                                : null,
                          ),
                        ),
                      ),
                      if (_isSending) const _TypingIndicator(),
                    ],
                  );
                },
              ),
            ),
            _MessageInput(
              controller: _messageController,
              focusNode: _messageFocusNode,
              isSending: _isSending,
              isListening: _isListening,
              onVoicePressed: _startVoiceInput,
              onSendPressed: () {
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추천 질문',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MockChatData.suggestedQuestions.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (context, index) {
              final question = MockChatData.suggestedQuestions[index];

              return ActionChip(
                label: Text(question),
                onPressed: () {
                  onSelected(question);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : message.isError
              ? AppColors.danger.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: message.isError ? AppColors.danger : AppColors.border,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUser
                    ? Colors.white
                    : message.isError
                    ? AppColors.danger
                    : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (message.isError && onRetry != null) ...[
              const SizedBox(height: 6),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('답변을 작성하고 있습니다...'),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isListening,
    required this.onVoicePressed,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isListening;
  final VoidCallback onVoicePressed;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: '음성 입력',
            onPressed: isSending ? null : onVoicePressed,
            icon: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: isListening ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              enabled: !isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: isListening ? '음성을 듣고 있습니다...' : '궁금한 내용을 입력해주세요.',
                counterText: '',
              ),
              maxLength: 500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: '전송',
            onPressed: isSending ? null : onSendPressed,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
