import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bank_question_model.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';

class QuestionBankRepository {
  static const String _storageKey = 'question_bank';
  static const String _seededKey = 'question_bank_seeded';

  Future<List<BankQuestion>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => BankQuestion.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// يضيف الأسئلة للبنك. السؤال المتكرر (نفس البصمة) يتحدّث ولا يتكرر.
  Future<void> addQuestions(
    List<QuestionModel> questions, {
    required String subject,
    required String grade,
  }) async {
    if (questions.isEmpty) return;
    final items = await getAll();
    _merge(items, questions, subject: subject, grade: grade);
    await _saveAll(items);
  }

  /// يعدّل سؤالًا في البنك فقط (لا يلمس أي امتحان). لو التعديل خلّى السؤال
  /// مطابقًا لسؤال تاني في البنك، بيتم دمجهم عشان ما يتكررش.
  Future<void> update(
    String id,
    QuestionModel question, {
    String? subject,
    String? grade,
  }) async {
    final items = await getAll();
    final index = items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    items[index] = items[index].copyWith(
      question: question,
      subject: subject,
      grade: grade,
    );
    final signature = items[index].signature;
    items.removeWhere((i) => i.id != id && i.signature == signature);
    await _saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await getAll();
    items.removeWhere((item) => item.id == id);
    await _saveAll(items);
  }

  Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seededKey) ?? false;
  }

  /// مرة واحدة فقط: يملأ البنك بأسئلة الامتحانات المحفوظة قبل إضافة الميزة.
  Future<void> seedFromExams(List<ExamModel> exams) async {
    final items = await getAll();
    for (final exam in exams.reversed) {
      _merge(items, exam.questions, subject: exam.subject, grade: exam.grade);
    }
    await _saveAll(items);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, true);
  }

  void _merge(
    List<BankQuestion> items,
    List<QuestionModel> questions, {
    required String subject,
    required String grade,
  }) {
    final now = DateTime.now();
    final added = <BankQuestion>[];
    var counter = 0;

    for (final question in questions) {
      final signature = question.signature;

      final existingIndex = items.indexWhere((i) => i.signature == signature);
      if (existingIndex != -1) {
        items[existingIndex] = items[existingIndex].copyWith(question: question);
        continue;
      }

      final addedIndex = added.indexWhere((i) => i.signature == signature);
      if (addedIndex != -1) continue;

      added.add(
        BankQuestion(
          id: 'bank_${now.microsecondsSinceEpoch}_${counter++}',
          question: question,
          subject: subject,
          grade: grade,
          addedAt: now,
        ),
      );
    }

    items.insertAll(0, added);
  }

  Future<void> _saveAll(List<BankQuestion> items) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
    if (!success) throw Exception('تعذر حفظ بنك الأسئلة على الجهاز');
  }
}
