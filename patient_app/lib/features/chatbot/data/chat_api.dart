import '../../../core/network/api_client.dart';
import 'models/chat_response.dart';

class ChatApi {
  ChatApi(this._apiClient);

  final ApiClient _apiClient;

  Future<ChatResponse> sendMessage(String message) async {
    final response = await _apiClient.post<dynamic>(
      '/ai/chat',
      data: <String, dynamic>{'message': message},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('챗봇 응답은 객체여야 합니다.');
    }
    return ChatResponse.fromJson(data);
  }
}
