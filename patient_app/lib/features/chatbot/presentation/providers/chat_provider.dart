import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/chat_message.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/mock_chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  bool _isSending = false;

  bool get isSending => _isSending;

  @override
  Future<List<ChatMessage>> build() async {
    final repository = ref.read(chatRepositoryProvider);

    return repository.getInitialMessages();
  }

  Future<bool> sendMessage(String content) async {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty || _isSending) {
      return false;
    }

    final currentMessages = state.value ?? [];
    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.user,
      content: trimmedContent,
      createdAt: DateTime.now(),
    );

    _isSending = true;

    state = AsyncData([
      ...currentMessages,
      userMessage,
    ]);

    try {
      final repository = ref.read(chatRepositoryProvider);

      final assistantMessage = await repository.sendMessage(
        trimmedContent,
      );

      final updatedMessages = state.value ?? [];

      state = AsyncData([
        ...updatedMessages,
        assistantMessage,
      ]);

      return true;
    } catch (error) {
      final updatedMessages = state.value ?? [];

      final errorMessage = ChatMessage(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        sender: ChatSender.assistant,
        content: '답변을 불러오지 못했습니다. 다시 시도해주세요.',
        createdAt: DateTime.now(),
        isError: true,
      );

      state = AsyncData([
        ...updatedMessages,
        errorMessage,
      ]);

      return false;
    } finally {
      _isSending = false;
    }
  }

  Future<void> resetChat() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(chatRepositoryProvider);

      return repository.getInitialMessages();
    });
  }
}