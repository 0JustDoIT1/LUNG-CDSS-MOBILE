enum ChatSender {
  user,
  assistant,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  final String id;
  final ChatSender sender;
  final String content;
  final DateTime createdAt;
  final bool isError;

  bool get isUser => sender == ChatSender.user;

  ChatMessage copyWith({
    String? id,
    ChatSender? sender,
    String? content,
    DateTime? createdAt,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isError: isError ?? this.isError,
    );
  }
}