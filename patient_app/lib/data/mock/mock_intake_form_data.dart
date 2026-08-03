import '../models/intake_form.dart';

class MockIntakeFormData {
  const MockIntakeFormData._();

  static final IntakeForm form = IntakeForm(
    id: 'intake-001',
    title: '진료 전 문진표',
    questions: const [
      IntakeQuestion(
        id: 'question-001',
        title: '현재 가장 불편한 증상을 선택해주세요.',
        type: IntakeQuestionType.multipleChoice,
        description: '해당하는 증상을 모두 선택할 수 있습니다.',
        options: [
          '기침',
          '가래',
          '호흡곤란',
          '가슴 통증',
          '발열',
          '피로',
          '체중 감소',
          '기타',
        ],
      ),
      IntakeQuestion(
        id: 'question-002',
        title: '현재 증상이 평소보다 심해졌나요?',
        type: IntakeQuestionType.singleChoice,
        options: [
          '아니요',
          '조금 심해졌습니다',
          '많이 심해졌습니다',
        ],
      ),
      IntakeQuestion(
        id: 'question-003',
        title: '최근 복약을 빠뜨린 적이 있나요?',
        type: IntakeQuestionType.singleChoice,
        options: [
          '없습니다',
          '1회 있습니다',
          '2회 이상 있습니다',
        ],
      ),
      IntakeQuestion(
        id: 'question-004',
        title: '최근 새롭게 복용한 약이 있나요?',
        type: IntakeQuestionType.singleChoice,
        options: [
          '없습니다',
          '있습니다',
        ],
      ),
      IntakeQuestion(
        id: 'question-005',
        title: '새롭게 복용한 약이 있다면 입력해주세요.',
        type: IntakeQuestionType.shortText,
        isRequired: false,
      ),
      IntakeQuestion(
        id: 'question-006',
        title: '최근 응급실 또는 다른 의료기관을 방문했나요?',
        type: IntakeQuestionType.singleChoice,
        options: [
          '아니요',
          '예',
        ],
      ),
      IntakeQuestion(
        id: 'question-007',
        title: '의료진에게 미리 질문하고 싶은 내용을 적어주세요.',
        type: IntakeQuestionType.longText,
        description: '진료 전 질문 목록으로 의료진에게 전달됩니다.',
        isRequired: false,
      ),
    ],
    answers: const {},
    isCompleted: false,
  );
}