import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import 'models/chat_response.dart';

class ChatApi {
  ChatApi({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static String get developmentBaseUrl =>
      kIsWeb ? 'http://localhost:3400' : 'http://10.0.2.2:3400';

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: developmentBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 10),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<ChatResponse> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError.value(message, 'message', '메시지는 비어 있을 수 없습니다.');
    }

    try {
      final response = await _dio.post<dynamic>(
        '/patientChatFlow',
        data: <String, dynamic>{
          'data': <String, dynamic>{'message': trimmedMessage},
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('챗봇 응답은 객체여야 합니다.');
      }
      return ChatResponse.fromJson(data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  static ApiException _toApiException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'Genkit request timed out.',
        code: 'TIMEOUT',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Could not connect to the local Genkit server.',
        code: 'CONNECTION_ERROR',
      );
    }
    return ApiException(
      statusCode: error.response?.statusCode,
      message: 'The local Genkit request failed.',
    );
  }
}
