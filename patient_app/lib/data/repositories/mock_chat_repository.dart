import '../mock/mock_chat_data.dart';
import '../models/chat_message.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  @override
  Future<List<ChatMessage>> getInitialMessages() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    return List<ChatMessage>.from(
      MockChatData.initialMessages,
    );
  }

  @override
  Future<ChatMessage> sendMessage(
    String question,
  ) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    final answer = MockChatData.createAnswer(
      question,
    );

    return ChatMessage(
      id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
      sender: ChatSender.assistant,
      content: answer,
      createdAt: DateTime.now(),
    );
  }
}