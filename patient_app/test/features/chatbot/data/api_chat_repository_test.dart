import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/chatbot/data/api_chat_repository.dart';
import 'package:patient_app/features/chatbot/data/chat_api.dart';

void main() {
  test('returns the backend answer as an assistant message', () async {
    final repository = ApiChatRepository(
      ChatApi(_ResponseClient({'answer': '백엔드 응답'})),
    );

    final message = await repository.sendMessage('질문');

    expect(message.content, '백엔드 응답');
    expect(message.isUser, isFalse);
  });

  test('preserves ApiException', () async {
    const error = ApiException(message: 'failed', statusCode: 429);
    final repository = ApiChatRepository(ChatApi(_ResponseClient(null, error)));
    await expectLater(repository.sendMessage('질문'), throwsA(same(error)));
  });

  test('preserves FormatException', () async {
    final repository = ApiChatRepository(
      ChatApi(_ResponseClient(<String, dynamic>{})),
    );
    await expectLater(repository.sendMessage('질문'), throwsFormatException);
  });
}

class _ResponseClient extends ApiClient {
  _ResponseClient(this.value, [this.error]) : super(dio: Dio());
  final Object? value;
  final Object? error;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (error != null) throw error!;
    return Response<T>(
      data: value as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
