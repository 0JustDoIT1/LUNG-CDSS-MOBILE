import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/chatbot/data/chat_api.dart';

void main() {
  test('posts only message to the exact endpoint and parses answer', () async {
    final client = _FakeApiClient(responseData: {'answer': '답변'});

    final response = await ChatApi(client).sendMessage('질문');

    expect(client.path, '/ai/chat');
    expect(client.data, <String, dynamic>{'message': '질문'});
    expect(
      (client.data! as Map<String, dynamic>).containsKey('thread_id'),
      isFalse,
    );
    expect(
      (client.data! as Map<String, dynamic>).containsKey('model'),
      isFalse,
    );
    expect(response.answer, '답변');
  });

  test('rejects a non-object response', () async {
    await expectLater(
      ChatApi(_FakeApiClient(responseData: <dynamic>[])).sendMessage('질문'),
      throwsFormatException,
    );
  });

  test('preserves ApiException', () async {
    const error = ApiException(message: 'failed', statusCode: 403);
    await expectLater(
      ChatApi(_FakeApiClient(error: error)).sendMessage('질문'),
      throwsA(same(error)),
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  String? path;
  Object? data;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    this.data = data;
    if (error != null) throw error!;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
