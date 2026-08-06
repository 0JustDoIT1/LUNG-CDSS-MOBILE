import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'models/symptom_submit_request.dart';

class SymptomApi {
  SymptomApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> fetchMySymptomRecords() async {
    final response = await _apiClient.get<dynamic>(
      '/api/symptoms/checks/mine/',
    );
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const FormatException('증상 기록 목록 응답은 배열이어야 합니다.');
    }
    return data;
  }

  Future<Map<String, dynamic>> submitSymptoms(
    SymptomSubmitRequest request,
  ) async {
    const path = '/api/symptoms/checks/';
    final requestMarker = Object();
    final debugInterceptor = InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode &&
            identical(
              error.requestOptions.extra[_symptomSaveRequestMarker],
              requestMarker,
            )) {
          final response = error.response;
          final data = response?.data;
          debugPrint('[SymptomSave] method=${error.requestOptions.method}');
          debugPrint('[SymptomSave] path=${error.requestOptions.path}');
          debugPrint('[SymptomSave] dioType=${error.type.name}');
          debugPrint('[SymptomSave] statusCode=${response?.statusCode}');
          debugPrint(
            '[SymptomSave] contentType='
            '${response?.headers.value(Headers.contentTypeHeader)}',
          );
          debugPrint('[SymptomSave] dataType=${data.runtimeType}');
          if (data is String) {
            final normalized = data.replaceAll(RegExp(r'\s+'), ' ').trim();
            final preview = normalized.length <= 150
                ? normalized
                : normalized.substring(0, 150);
            debugPrint('[SymptomSave] preview=$preview');
          }
        }
        handler.next(error);
      },
    );

    _apiClient.dio.interceptors.add(debugInterceptor);
    try {
      final response = await _apiClient.post<dynamic>(
        path,
        data: request.toJson(),
        options: Options(
          extra: <String, Object>{
            _symptomSaveRequestMarker: requestMarker,
          },
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('증상 기록 저장 응답은 객체여야 합니다.');
      }
      return data;
    } finally {
      _apiClient.dio.interceptors.remove(debugInterceptor);
    }
  }
}

const _symptomSaveRequestMarker = 'symptomSaveRequestMarker';
