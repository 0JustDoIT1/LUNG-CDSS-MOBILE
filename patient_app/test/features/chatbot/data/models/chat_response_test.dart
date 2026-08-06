import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/chatbot/data/models/chat_response.dart';

void main() {
  test('parses and trims result.answer', () {
    final response = ChatResponse.fromJson({
      'result': {'answer': ' 응답 '},
    });
    expect(response.answer, '응답');
  });

  for (final value in <Object?>[null, '', '   ', 1, true]) {
    test('rejects invalid answer value $value', () {
      expect(
        () => ChatResponse.fromJson({
          'result': {'answer': value},
        }),
        throwsFormatException,
      );
    });
  }

  test('rejects a missing or invalid result object', () {
    expect(() => ChatResponse.fromJson({}), throwsFormatException);
    expect(
      () => ChatResponse.fromJson({'result': <dynamic>[]}),
      throwsFormatException,
    );
  });
}
