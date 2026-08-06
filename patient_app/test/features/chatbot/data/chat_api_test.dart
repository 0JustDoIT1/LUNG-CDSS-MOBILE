import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/chatbot/data/chat_api.dart';

void main() {
  test('posts only data.message and parses result.answer', () async {
    final recorder = _RecordingInterceptor(
      responseData: <String, dynamic>{
        'result': <String, dynamic>{'answer': ' Gemini 응답 '},
      },
    );
    final dio = Dio()..interceptors.add(recorder);

    final response = await ChatApi(dio: dio).sendMessage(' 질문 ');

    expect(recorder.path, '/patientChatFlow');
    expect(recorder.method, 'POST');
    expect(recorder.data, <String, dynamic>{
      'data': <String, dynamic>{'message': '질문'},
    });
    expect(recorder.headers.containsKey('Authorization'), isFalse);
    expect(response.answer, 'Gemini 응답');
  });

  test('rejects a non-object response', () async {
    final dio = Dio()
      ..interceptors.add(_RecordingInterceptor(responseData: <dynamic>[]));
    await expectLater(
      ChatApi(dio: dio).sendMessage('질문'),
      throwsFormatException,
    );
  });

  test('maps connection errors without exposing the Dio exception', () async {
    final dio = Dio()
      ..interceptors.add(
        _RecordingInterceptor(errorType: DioExceptionType.connectionError),
      );

    await expectLater(
      ChatApi(dio: dio).sendMessage('질문'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'CONNECTION_ERROR',
        ),
      ),
    );
  });

  test('maps timeout errors', () async {
    final dio = Dio()
      ..interceptors.add(
        _RecordingInterceptor(errorType: DioExceptionType.receiveTimeout),
      );

    await expectLater(
      ChatApi(dio: dio).sendMessage('질문'),
      throwsA(
        isA<ApiException>().having((error) => error.code, 'code', 'TIMEOUT'),
      ),
    );
  });
}

class _RecordingInterceptor extends Interceptor {
  _RecordingInterceptor({this.responseData, this.errorType});

  final Object? responseData;
  final DioExceptionType? errorType;
  String? path;
  String? method;
  Object? data;
  Map<String, dynamic> headers = <String, dynamic>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    path = options.path;
    method = options.method;
    data = options.data;
    headers = Map<String, dynamic>.from(options.headers);
    if (errorType != null) {
      handler.reject(DioException(requestOptions: options, type: errorType!));
      return;
    }
    handler.resolve(
      Response<dynamic>(data: responseData, requestOptions: options),
    );
  }
}
