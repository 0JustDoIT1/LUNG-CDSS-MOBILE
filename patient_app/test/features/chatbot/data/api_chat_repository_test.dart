import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/chatbot/data/api_chat_repository.dart';
import 'package:patient_app/features/chatbot/data/chat_api.dart';
import 'package:patient_app/features/chatbot/data/models/chat_response.dart';
import 'package:patient_app/core/network/api_client.dart';

void main() {
  test('returns the Genkit answer as an assistant message', () async {
    final repository = ApiChatRepository(_FakeChatApi());

    final message = await repository.sendMessage('질문');

    expect(message.content, '서버 응답');
    expect(message.isUser, isFalse);
  });

  test('preserves ApiException', () async {
    const error = ApiException(message: 'failed', statusCode: 500);
    final repository = ApiChatRepository(_FakeChatApi(error: error));
    await expectLater(repository.sendMessage('질문'), throwsA(same(error)));
  });

  test('preserves response parsing errors', () async {
    final repository = ApiChatRepository(
      _FakeChatApi(error: const FormatException('invalid')),
    );
    await expectLater(repository.sendMessage('질문'), throwsFormatException);
  });
}

class _FakeChatApi extends ChatApi {
  _FakeChatApi({this.error}) : super(ApiClient(dio: Dio()));

  final Object? error;

  @override
  Future<ChatResponse> sendMessage(String message) async {
    if (error != null) throw error!;
    return const ChatResponse(answer: '서버 응답');
  }
}
