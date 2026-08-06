import '../../../core/network/api_client.dart';
import 'models/chat_response.dart';

class ChatApi {
  ChatApi(this._apiClient);

  final ApiClient _apiClient;

  Future<ChatResponse> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError.value(message, 'message', '메시지는 비어 있을 수 없습니다.');
    }

    final response = await _apiClient.post<dynamic>(
      '/ai/chat',
      data: <String, dynamic>{'message': trimmedMessage},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('챗봇 응답은 객체여야 합니다.');
    }
    return ChatResponse.fromJson(data);
  }
}
