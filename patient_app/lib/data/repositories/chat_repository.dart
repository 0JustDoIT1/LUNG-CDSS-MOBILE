import '../models/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getInitialMessages();

  Future<ChatMessage> sendMessage(
    String question,
  );
}