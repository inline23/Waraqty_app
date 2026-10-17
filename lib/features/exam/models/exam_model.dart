import 'question_model.dart';

class ExamModel {
  final String id;
  final String title;
  final String subject;
  final String grade;
  final String? teacherName;
  final int durationMinutes;
  final String? instructions;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    this.teacherName,
    required this.durationMinutes,
    this.instructions,
    this.questions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalMarks => questions.fold(0, (sum, question) => sum + question.marks);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'grade': grade,
    'teacherName': teacherName,
    'durationMinutes': durationMinutes,
    'instructions': instructions,
    'questions': questions.map((q) => q.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ExamModel.fromJson(Map<String, dynamic> json) => ExamModel(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    teacherName: json['teacherName'] as String?,
    durationMinutes: (json['durationMinutes'] as num? ?? 60).toInt(),
    instructions: json['instructions'] as String?,
    questions: (json['questions'] as List<dynamic>? ?? const [])
        .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  ExamModel copyWith({
    String? id, String? title, String? subject, String? grade,
    String? teacherName, int? durationMinutes, String? instructions,
    List<QuestionModel>? questions, DateTime? createdAt, DateTime? updatedAt,
  }) => ExamModel(
    id: id ?? this.id,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    grade: grade ?? this.grade,
    teacherName: teacherName ?? this.teacherName,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    instructions: instructions ?? this.instructions,
    questions: questions ?? this.questions,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
