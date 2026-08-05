class ChatResponse {
  const ChatResponse({required this.answer});

  final String answer;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'];
    if (answer is! String) {
      throw const FormatException('챗봇 응답 형식이 올바르지 않습니다.');
    }
    return ChatResponse(answer: answer);
  }
}
