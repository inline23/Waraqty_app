import 'question_model.dart';

/// سؤال محفوظ في بنك الأسئلة (يُضاف تلقائيًا عند حفظ أي امتحان).
class BankQuestion {
  final String id;
  final QuestionModel question;
  final String subject;
  final String grade;
  final DateTime addedAt;

  const BankQuestion({
    required this.id,
    required this.question,
    required this.subject,
    required this.grade,
    required this.addedAt,
  });

  /// بصمة السؤال: نفس النوع + النص + البدائل = نفس السؤال.
  String get signature => question.signature;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question.toJson(),
    'subject': subject,
    'grade': grade,
    'addedAt': addedAt.toIso8601String(),
  };

  factory BankQuestion.fromJson(Map<String, dynamic> json) => BankQuestion(
    id: json['id'] as String,
    question: QuestionModel.fromJson(
      Map<String, dynamic>.from(json['question'] as Map),
    ),
    subject: json['subject'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    addedAt:
        DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
  );

  BankQuestion copyWith({
    QuestionModel? question,
    String? subject,
    String? grade,
  }) => BankQuestion(
    id: id,
    question: question ?? this.question,
    subject: subject ?? this.subject,
    grade: grade ?? this.grade,
    addedAt: addedAt,
  );
}
