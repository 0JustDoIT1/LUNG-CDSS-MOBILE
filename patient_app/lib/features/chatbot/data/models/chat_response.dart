class ChatResponse {
  const ChatResponse({required this.answer});

  final String answer;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      throw const FormatException('챗봇 응답의 result 형식이 올바르지 않습니다.');
    }
    final answer = result['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const FormatException('챗봇 응답의 answer 형식이 올바르지 않습니다.');
    }
    return ChatResponse(answer: answer.trim());
  }
}
