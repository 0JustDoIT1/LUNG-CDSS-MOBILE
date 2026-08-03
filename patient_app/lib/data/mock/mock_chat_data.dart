import '../models/chat_message.dart';

class MockChatData {
  const MockChatData._();

  static final List<ChatMessage> initialMessages = [
    ChatMessage(
      id: 'message-welcome',
      sender: ChatSender.assistant,
      content:
          '안녕하세요. 숨잇 AI 챗봇입니다.\n'
          '검사결과, 복약, 증상 기록, 진료 준비에 대해 질문해주세요.',
      createdAt: DateTime(
        2026,
        8,
        3,
        9,
      ),
    ),
  ];

  static const List<String> suggestedQuestions = [
    '최근 검사결과를 설명해주세요.',
    '오늘 복용할 약을 알려주세요.',
    '진료 전에 무엇을 준비해야 하나요?',
    '기침이 심해졌을 때 어떻게 해야 하나요?',
  ];

  static String createAnswer(String question) {
    final normalizedQuestion = question.trim();

    if (normalizedQuestion.contains('검사')) {
      return '최근 검사결과에서는 폐암 아형 분류와 '
          '유전자 변이 가능성을 확인할 수 있습니다. '
          '예측 결과는 참고 정보이며, 최종 판단은 담당 의료진의 '
          '설명과 확진 검사 결과를 함께 확인해야 합니다.';
    }

    if (normalizedQuestion.contains('약') ||
        normalizedQuestion.contains('복용') ||
        normalizedQuestion.contains('복약')) {
      return '오늘의 복약 일정은 증상·복약 화면에서 확인할 수 있습니다. '
          '약 이름, 복용 시간과 복용 방법을 확인하고 실제로 복용한 뒤 '
          '체크해주세요. 임의로 복용량을 변경하거나 중단하지 마세요.';
    }

    if (normalizedQuestion.contains('진료') ||
        normalizedQuestion.contains('예약') ||
        normalizedQuestion.contains('준비')) {
      return '진료 전에는 문진표를 작성하고, 최근 증상 변화와 '
          '현재 복용 중인 약을 확인해두는 것이 좋습니다. '
          '예약 일시와 장소는 예약 화면에서 확인할 수 있습니다.';
    }

    if (normalizedQuestion.contains('기침') ||
        normalizedQuestion.contains('호흡') ||
        normalizedQuestion.contains('통증')) {
      return '증상이 새로 생기거나 심해졌다면 증상 기록에 남겨주세요. '
          '호흡이 매우 어렵거나 갑작스러운 심한 통증 등 응급 증상이 있으면 '
          '챗봇 답변에 의존하지 말고 즉시 의료기관의 도움을 받아야 합니다.';
    }

    return '질문하신 내용은 담당 의료진에게 확인하는 것이 가장 정확합니다. '
        '숨잇에서는 검사결과, 복약 일정, 증상 기록과 예약 정보를 '
        '확인할 수 있습니다.';
  }
}