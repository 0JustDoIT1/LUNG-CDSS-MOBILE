enum IntakeStatus { draft, submitted }

enum IntakeQuestionType { singleChoice, multipleChoice, text }

class IntakeQuestion {
  const IntakeQuestion({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.required,
    required this.answer,
  });

  final String questionId;
  final String questionText;
  final IntakeQuestionType questionType;
  final List<String> options;
  final bool required;
  final Object? answer;

  String get id => questionId;
  String get title => questionText;
  IntakeQuestionType get type => questionType;
  bool get isRequired => required;

  IntakeQuestion copyWith({Object? answer, bool clearAnswer = false}) {
    return IntakeQuestion(
      questionId: questionId,
      questionText: questionText,
      questionType: questionType,
      options: options,
      required: required,
      answer: clearAnswer ? null : answer ?? this.answer,
    );
  }

  factory IntakeQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['question_id'];
    final text = json['question_text'];
    final typeValue = json['question_type'];
    final optionsValue = json['options'];
    final requiredValue = json['required'];
    if (id is! String ||
        text is! String ||
        typeValue is! String ||
        optionsValue is! List<dynamic> ||
        requiredValue is! bool ||
        optionsValue.any((option) => option is! String)) {
      throw const FormatException('문진 질문 형식이 올바르지 않습니다.');
    }

    final type = switch (typeValue) {
      'single_choice' => IntakeQuestionType.singleChoice,
      'multiple_choice' => IntakeQuestionType.multipleChoice,
      'text' => IntakeQuestionType.text,
      _ => throw const FormatException('알 수 없는 문진 질문 유형입니다.'),
    };
    final answer = json['answer'];
    switch (type) {
      case IntakeQuestionType.singleChoice:
      case IntakeQuestionType.text:
        if (answer != null && answer is! String) {
          throw const FormatException('문진 답변 형식이 올바르지 않습니다.');
        }
      case IntakeQuestionType.multipleChoice:
        if (answer != null &&
            (answer is! List<dynamic> ||
                answer.any((value) => value is! String))) {
          throw const FormatException('문진 답변 형식이 올바르지 않습니다.');
        }
    }

    return IntakeQuestion(
      questionId: id,
      questionText: text,
      questionType: type,
      options: List<String>.unmodifiable(optionsValue.cast<String>()),
      required: requiredValue,
      answer: answer is List<dynamic>
          ? List<String>.unmodifiable(answer.cast<String>())
          : answer,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'question_id': questionId,
    'question_text': questionText,
    'question_type': switch (questionType) {
      IntakeQuestionType.singleChoice => 'single_choice',
      IntakeQuestionType.multipleChoice => 'multiple_choice',
      IntakeQuestionType.text => 'text',
    },
    'options': options,
    'required': required,
    'answer': answer,
  };
}

class IntakeContent {
  const IntakeContent({required this.status, required this.questions});

  final IntakeStatus status;
  final List<IntakeQuestion> questions;

  factory IntakeContent.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    final questionsValue = json['questions'];
    if (statusValue is! String || questionsValue is! List<dynamic>) {
      throw const FormatException('문진 내용 형식이 올바르지 않습니다.');
    }
    final status = switch (statusValue) {
      'draft' => IntakeStatus.draft,
      'submitted' => IntakeStatus.submitted,
      _ => throw const FormatException('알 수 없는 문진 상태입니다.'),
    };
    final ids = <String>{};
    final questions = questionsValue
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('문진 질문은 객체여야 합니다.');
          }
          final question = IntakeQuestion.fromJson(item);
          if (!ids.add(question.questionId)) {
            throw const FormatException('중복된 문진 질문 ID입니다.');
          }
          return question;
        })
        .toList(growable: false);
    return IntakeContent(status: status, questions: questions);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.name,
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

class IntakeForm {
  const IntakeForm({
    required this.id,
    required this.content,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final IntakeContent content;
  final DateTime? submittedAt;
  final DateTime updatedAt;

  List<IntakeQuestion> get questions => content.questions;
  bool get isCompleted => content.status == IntakeStatus.submitted;
  DateTime? get completedAt => submittedAt;

  factory IntakeForm.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final contentValue = json['content'];
    final submittedAtValue = json['submitted_at'];
    final updatedAtValue = json['updated_at'];
    if (id is! String ||
        contentValue is! Map<String, dynamic> ||
        (submittedAtValue != null && submittedAtValue is! String) ||
        updatedAtValue is! String) {
      throw const FormatException('문진 응답 형식이 올바르지 않습니다.');
    }
    final submittedAt = submittedAtValue == null
        ? null
        : DateTime.tryParse(submittedAtValue);
    final updatedAt = DateTime.tryParse(updatedAtValue);
    if (updatedAt == null ||
        (submittedAtValue != null && submittedAt == null)) {
      throw const FormatException('문진 날짜 형식이 올바르지 않습니다.');
    }
    return IntakeForm(
      id: id,
      content: IntakeContent.fromJson(contentValue),
      submittedAt: submittedAt,
      updatedAt: updatedAt,
    );
  }

  IntakeForm copyWithQuestions(List<IntakeQuestion> questions) => IntakeForm(
    id: id,
    content: IntakeContent(status: content.status, questions: questions),
    submittedAt: submittedAt,
    updatedAt: updatedAt,
  );
}
