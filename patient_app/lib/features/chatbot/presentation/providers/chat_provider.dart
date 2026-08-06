import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../data/api_chat_repository.dart';
import '../../data/chat_api.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ApiChatRepository(ChatApi());
});

final chatProvider = AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  static const int maxMessageLength = 500;

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
    if (trimmedContent.isEmpty ||
        trimmedContent.length > maxMessageLength ||
        _isSending) {
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
  if (error is FormatException) return '챗봇 응답 형식을 확인할 수 없습니다.';
  if (error is ApiException) {
    if (error.statusCode == 400) return '질문 내용을 확인해 주세요.';
    if (error.statusCode == 403) return '챗봇을 이용할 권한이 없습니다.';
    if (error.statusCode == 404) return '로컬 챗봇 경로를 찾을 수 없습니다.';
    if (error.statusCode == 429) {
      return '요청이 많습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (error.statusCode == 500 ||
        error.statusCode == 502 ||
        error.statusCode == 503) {
      return '답변을 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (error.code == 'TIMEOUT') {
      return '답변 생성 시간이 초과되었습니다. 다시 시도해 주세요.';
    }
    if (error.code == 'CONNECTION_ERROR') {
      return '로컬 챗봇 서버에 연결할 수 없습니다. Genkit 서버 실행 상태를 확인해 주세요.';
    }
  }
  return '메시지 전송에 실패했습니다.';
}
