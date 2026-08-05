import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/mock/mock_chat_data.dart';
import 'chat_api.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._api);

  final ChatApi _api;

  @override
  Future<List<ChatMessage>> getInitialMessages() async {
    return List<ChatMessage>.from(MockChatData.initialMessages);
  }

  @override
  Future<ChatMessage> sendMessage(String question) async {
    final response = await _api.sendMessage(question);
    return ChatMessage(
      id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
      sender: ChatSender.assistant,
      content: response.answer,
      createdAt: DateTime.now(),
    );
  }
}
