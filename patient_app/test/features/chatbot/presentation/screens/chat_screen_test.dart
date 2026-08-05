import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/data/models/chat_message.dart';
import 'package:patient_app/data/repositories/chat_repository.dart';
import 'package:patient_app/features/chatbot/presentation/providers/chat_provider.dart';
import 'package:patient_app/features/chatbot/presentation/screens/chat_screen.dart';

void main() {
  testWidgets('keeps voice input and renders user and backend messages', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _FakeRepository(gate.future);
    await _pump(tester, repository);

    expect(find.byTooltip('음성 입력'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '백엔드 질문');
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();

    expect(find.text('백엔드 질문'), findsNWidgets(2));
    expect(find.text('답변을 작성하고 있습니다...'), findsOneWidget);
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('서버 답변'), findsOneWidget);
    expect(find.text('답변을 작성하고 있습니다...'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('does not send blank input', (tester) async {
    final repository = _FakeRepository(null);
    await _pump(tester, repository);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();

    expect(repository.calls, 0);
  });
}

Future<void> _pump(WidgetTester tester, ChatRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ChatScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

class _FakeRepository implements ChatRepository {
  _FakeRepository(this.gate);
  final Future<void>? gate;
  int calls = 0;

  @override
  Future<List<ChatMessage>> getInitialMessages() async => [];

  @override
  Future<ChatMessage> sendMessage(String question) async {
    calls++;
    if (gate != null) await gate;
    return ChatMessage(
      id: 'answer',
      sender: ChatSender.assistant,
      content: '서버 답변',
      createdAt: DateTime(2026, 8, 5),
    );
  }
}
