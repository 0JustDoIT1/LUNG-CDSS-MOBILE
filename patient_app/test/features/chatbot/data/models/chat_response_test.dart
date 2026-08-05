import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/chatbot/data/models/chat_response.dart';

void main() {
  test('parses an answer', () {
    expect(ChatResponse.fromJson({'answer': '응답'}).answer, '응답');
  });

  test('keeps an empty answer unchanged', () {
    expect(ChatResponse.fromJson({'answer': ''}).answer, isEmpty);
  });

  for (final value in <Object?>[null, 1, true]) {
    test('rejects invalid answer value $value', () {
      expect(
        () => ChatResponse.fromJson({'answer': value}),
        throwsFormatException,
      );
    });
  }

  test('rejects a missing answer', () {
    expect(() => ChatResponse.fromJson({}), throwsFormatException);
  });
}
