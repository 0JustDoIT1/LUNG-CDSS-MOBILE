import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/data/models/chat_message.dart';
import 'package:patient_app/data/repositories/chat_repository.dart';
import 'package:patient_app/features/chatbot/presentation/providers/chat_provider.dart';

void main() {
  test('blocks empty and over-length input', () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(chatProvider.future);

    expect(
      await container.read(chatProvider.notifier).sendMessage('   '),
      isFalse,
    );
    expect(
      await container
          .read(chatProvider.notifier)
          .sendMessage(List<String>.filled(501, '가').join()),
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
    expect(messages.map((item) => item.content), ['질문', '서버 응답']);
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
    final repository = _FakeRepository(
      failures: 1,
      error: const ApiException(message: 'failed', statusCode: 429),
    );
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
    expect(messages.map((item) => item.content), ['질문', '서버 응답']);
    expect(repository.calls, 2);
  });

  for (final testCase in <({ApiException error, String message})>[
    (
      error: ApiException(message: 'failed', code: 'CONNECTION_ERROR'),
      message: '로컬 챗봇 서버에 연결할 수 없습니다. Genkit 서버 실행 상태를 확인해 주세요.',
    ),
    (
      error: ApiException(message: 'failed', code: 'TIMEOUT'),
      message: '답변 생성 시간이 초과되었습니다. 다시 시도해 주세요.',
    ),
    (
      error: ApiException(message: 'failed', statusCode: 400),
      message: '질문 내용을 확인해 주세요.',
    ),
    (
      error: ApiException(message: 'failed', statusCode: 401),
      message: '인증 정보가 만료됐거나 유효하지 않습니다.',
    ),
    (
      error: ApiException(message: 'failed', statusCode: 502),
      message: '답변을 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.',
    ),
  ]) {
    test('shows the safe error message for ${testCase.error}', () async {
      final repository = _FakeRepository(failures: 1, error: testCase.error);
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(chatProvider.future);

      await container.read(chatProvider.notifier).sendMessage('질문');

      expect(
        container.read(chatProvider).requireValue.last.content,
        testCase.message,
      );
    });
  }
}

ProviderContainer _container(ChatRepository repository) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(chatProvider, (_, _) {});
  return container;
}

class _FakeRepository implements ChatRepository {
  _FakeRepository({this.gate, this.failures = 0, this.error});

  final Future<void>? gate;
  final int failures;
  final Object? error;
  int calls = 0;

  @override
  Future<List<ChatMessage>> getInitialMessages() async => [];

  @override
  Future<ChatMessage> sendMessage(String question) async {
    calls++;
    if (gate != null) await gate;
    if (calls <= failures) {
      throw error ?? const ApiException(message: 'failed', statusCode: 500);
    }
    return ChatMessage(
      id: 'answer-$calls',
      sender: ChatSender.assistant,
      content: '서버 응답',
      createdAt: DateTime(2026, 8, 5),
    );
  }
}
