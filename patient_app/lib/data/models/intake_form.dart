enum IntakeQuestionType {
  singleChoice,
  multipleChoice,
  shortText,
  longText,
}

class IntakeQuestion {
  const IntakeQuestion({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.options = const [],
    this.isRequired = true,
  });

  final String id;
  final String title;
  final IntakeQuestionType type;
  final String? description;
  final List<String> options;
  final bool isRequired;
}

class IntakeAnswer {
  const IntakeAnswer({
    required this.questionId,
    this.selectedOptions = const [],
    this.textAnswer = '',
  });

  final String questionId;
  final List<String> selectedOptions;
  final String textAnswer;

  bool get hasAnswer {
    return selectedOptions.isNotEmpty ||
        textAnswer.trim().isNotEmpty;
  }

  IntakeAnswer copyWith({
    String? questionId,
    List<String>? selectedOptions,
    String? textAnswer,
  }) {
    return IntakeAnswer(
      questionId: questionId ?? this.questionId,
      selectedOptions:
          selectedOptions ?? this.selectedOptions,
      textAnswer: textAnswer ?? this.textAnswer,
    );
  }
}

class IntakeForm {
  const IntakeForm({
    required this.id,
    required this.title,
    required this.questions,
    required this.answers,
    required this.isCompleted,
    this.completedAt,
  });

  final String id;
  final String title;
  final List<IntakeQuestion> questions;
  final Map<String, IntakeAnswer> answers;
  final bool isCompleted;
  final DateTime? completedAt;

  IntakeForm copyWith({
    String? id,
    String? title,
    List<IntakeQuestion>? questions,
    Map<String, IntakeAnswer>? answers,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return IntakeForm(
      id: id ?? this.id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}