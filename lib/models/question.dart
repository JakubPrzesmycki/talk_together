class Question {
  final String text;
  final String option1;
  final String option2;

  Question({
    required this.text,
    required this.option1,
    required this.option2,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: (json['text'] as String?)?.trim() ?? '',
      option1: (json['option1'] as String?)?.trim() ?? '',
      option2: (json['option2'] as String?)?.trim() ?? '',
    );
  }
}
