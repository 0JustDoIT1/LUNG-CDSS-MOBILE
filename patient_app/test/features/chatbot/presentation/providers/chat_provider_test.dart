import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/data/models/chat_message.dart';
import 'package:patient_app/data/repositories/chat_repository.dart';
import 'package:patient_app/features/chatbot/presentation/providers/chat_provider.dart';

void main() {
  test('blocks empty input without calling repository', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(chatProvider.future);

    expect(
      await container.read(chatProvider.notifier).sendMessage('   '),
      isFalse,
    );
    expect(repository.calls, 0);
  });

  test('adds user then assistant messages in order', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(chatProvider.future);

    expect(
      await container.read(chatProvider.notifier).sendMessage(' 질문 '),
      isTrue,
    );
    final messages = container.read(chatProvider).requireValue;
    expect(messages.map((item) => item.content), ['질문', '서버 답변']);
    expect(messages.first.isUser, isTrue);
    expect(messages.last.isUser, isFalse);
  });

  test('blocks duplicate sending while a request is pending', () async {
    final gate = Completer<void>();
    final repository = _FakeRepository(gate: gate.future);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(chatProvider.future);
    final notifier = container.read(chatProvider.notifier);

    final first = notifier.sendMessage('첫 질문');
    await Future<void>.delayed(Duration.zero);
    expect(await notifier.sendMessage('중복 질문'), isFalse);
    expect(repository.calls, 1);
    gate.complete();
    await first;
  });

  test('keeps the user message on failure and retries it', () async {
    final repository = _FakeRepository(failures: 1);
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(chatProvider.future);
    final notifier = container.read(chatProvider.notifier);

    expect(await notifier.sendMessage('질문'), isFalse);
    var messages = container.read(chatProvider).requireValue;
    expect(messages.first.content, '질문');
    expect(messages.last.isError, isTrue);
    expect(messages.last.content, '요청이 많습니다. 잠시 후 다시 시도해 주세요.');

    expect(await notifier.retryMessage(messages.last.id), isTrue);
    messages = container.read(chatProvider).requireValue;
    expect(messages.map((item) => item.content), ['질문', '서버 답변']);
    expect(repository.calls, 2);
  });
}

ProviderContainer _container(ChatRepository repository) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(chatProvider, (_, _) {});
  return container;
}

class _FakeRepository implements ChatRepository {
  _FakeRepository({this.gate, this.failures = 0});
  final Future<void>? gate;
  final int failures;
  int calls = 0;

  @override
  Future<List<ChatMessage>> getInitialMessages() async => [];

  @override
  Future<ChatMessage> sendMessage(String question) async {
    calls++;
    if (gate != null) await gate;
    if (calls <= failures) {
      throw const ApiException(message: 'failed', statusCode: 429);
    }
    return ChatMessage(
      id: 'answer-$calls',
      sender: ChatSender.assistant,
      content: '서버 답변',
      createdAt: DateTime(2026, 8, 5),
    );
  }
}
