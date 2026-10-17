import 'question_type.dart';

class QuestionModel {
  final String id;
  final QuestionType type;
  final String text;
  final double marks;
  final List<String> options;
  final String? correctAnswer;
  final int answerLines;
  final DateTime createdAt;

  const QuestionModel({
    required this.id,
    required this.type,
    required this.text,
    required this.marks,
    this.options = const [],
    this.correctAnswer,
    this.answerLines = 3,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'marks': marks,
    'options': options,
    'correctAnswer': correctAnswer,
    'answerLines': answerLines,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'multipleChoice';
    return QuestionModel(
      id: json['id'] as String,
      type: QuestionType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => QuestionType.multipleChoice,
      ),
      text: json['text'] as String? ?? '',
      marks: (json['marks'] as num? ?? 1).toDouble(),
      options: List<String>.from(json['options'] ?? const []),
      correctAnswer: json['correctAnswer'] as String?,
      answerLines: (json['answerLines'] as num? ?? 3).toInt(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  QuestionModel copyWith({
    String? id,
    QuestionType? type,
    String? text,
    double? marks,
    List<String>? options,
    String? correctAnswer,
    int? answerLines,
    DateTime? createdAt,
  }) => QuestionModel(
    id: id ?? this.id,
    type: type ?? this.type,
    text: text ?? this.text,
    marks: marks ?? this.marks,
    options: options ?? this.options,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    answerLines: answerLines ?? this.answerLines,
    createdAt: createdAt ?? this.createdAt,
  );
}
