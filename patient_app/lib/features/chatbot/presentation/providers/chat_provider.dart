import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/api_chat_repository.dart';
import '../../data/chat_api.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ApiChatRepository(ChatApi(ref.watch(apiClientProvider)));
});

final chatProvider = AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  bool _isSending = false;
  final Map<String, String> _failedContents = <String, String>{};

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

    state = AsyncData([...currentMessages, userMessage]);

    return _sendToRepository(trimmedContent);
  }

  Future<bool> retryMessage(String errorMessageId) async {
    final content = _failedContents[errorMessageId];
    if (content == null || _isSending) return false;

    final messages = state.value ?? const <ChatMessage>[];
    state = AsyncData(
      messages.where((message) => message.id != errorMessageId).toList(),
    );
    _failedContents.remove(errorMessageId);
    return _sendToRepository(content);
  }

  Future<bool> _sendToRepository(String content) async {
    _isSending = true;

    try {
      final repository = ref.read(chatRepositoryProvider);

      final assistantMessage = await repository.sendMessage(content);

      final updatedMessages = state.value ?? [];

      state = AsyncData([...updatedMessages, assistantMessage]);

      return true;
    } catch (error) {
      final updatedMessages = state.value ?? [];
      final errorMessageId = 'error-${DateTime.now().microsecondsSinceEpoch}';
      _failedContents[errorMessageId] = content;

      final errorMessage = ChatMessage(
        id: errorMessageId,
        sender: ChatSender.assistant,
        content: _chatErrorMessage(error),
        createdAt: DateTime.now(),
        isError: true,
      );

      state = AsyncData([...updatedMessages, errorMessage]);

      return false;
    } finally {
      _isSending = false;
    }
  }

  Future<void> resetChat() async {
    _failedContents.clear();
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(chatRepositoryProvider);

      return repository.getInitialMessages();
    });
  }
}

String _chatErrorMessage(Object error) {
  if (error is FormatException) return '메시지 전송에 실패했습니다.';
  if (error is ApiException) {
    if (error.statusCode == 400) return '메시지 내용을 확인해 주세요.';
    if (error.statusCode == 403) return '챗봇을 이용할 권한이 없습니다.';
    if (error.statusCode == 404) return '챗봇 서비스를 찾을 수 없습니다.';
    if (error.statusCode == 429) {
      return '요청이 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (error.code == 'TIMEOUT') return '응답 시간이 초과되었습니다.';
    if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해 주세요.';
  }
  return '메시지 전송에 실패했습니다.';
}
