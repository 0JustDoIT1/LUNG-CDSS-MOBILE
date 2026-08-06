import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// 문진표 질문 하나 (GET /api/intake/patient/{id}/ 의 content.questions[] 항목).
class IntakeAnswer {
  final String questionText;
  final String answerText;

  IntakeAnswer({required this.questionText, required this.answerText});

  factory IntakeAnswer.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'];
    return IntakeAnswer(
      questionText: json['question_text'] as String? ?? '',
      answerText: answer == null || (answer is String && answer.isEmpty)
          ? '응답 없음'
          : (answer is List ? answer.join(', ') : answer.toString()),
    );
  }
}

/// GET /api/intake/patient/{patient_id}/ 응답 — 간호사/의사가 환자 상세화면에서 조회하는 문진표(읽기전용).
class PatientIntake {
  final String status;
  final List<IntakeAnswer> answers;
  final DateTime? submittedAt;

  PatientIntake({required this.status, required this.answers, this.submittedAt});

  factory PatientIntake.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? json;
    final questions = (content['questions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return PatientIntake(
      status: content['status'] as String? ?? json['status'] as String? ?? '',
      answers: questions.map(IntakeAnswer.fromJson).toList(),
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at'] as String) : null,
    );
  }
}

/// GET /api/intake/patient/{patient_id}/ — 문진표 조회(간호사/의사, 읽기전용).
/// 아직 제출 전이면 서버가 404를 줄 수 있어 그 경우 null 반환.
Future<PatientIntake?> fetchPatientIntake(String patientId, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/intake/patient/$patientId/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode == 404) return null;

  if (response.statusCode != 200) {
    final body = utf8.decode(response.bodyBytes);
    final match = RegExp(r'<pre class="exception_value">(.*?)</pre>', dotAll: true).firstMatch(body);
    // ignore: avoid_print
    print('❗ fetchPatientIntake ${response.statusCode} exception: ${match?.group(1) ?? body}');
    throw ApiException('문진표를 불러오지 못했어요. (${response.statusCode})');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return PatientIntake.fromJson(body);
}
