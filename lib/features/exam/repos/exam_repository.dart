import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';

class ExamRepository {
  static const String _storageKey = 'saved_exams';
  static const String _subjectsKey = 'used_subjects';
  static const String _gradesKey = 'used_grades';

  // ─── Exams ───────────────────────────────────────────────────────────────

  Future<List<ExamModel>> getExams() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);
    if (savedData == null || savedData.isEmpty) return [];
    final decoded = jsonDecode(savedData) as List<dynamic>;
    return decoded.map((item) => ExamModel.fromJson(
      Map<String, dynamic>.from(item as Map),
    )).toList();
  }

  Future<void> saveExam(ExamModel exam) async {
    final exams = await getExams();
    final index = exams.indexWhere((item) => item.id == exam.id);
    if (index == -1) {
      exams.insert(0, exam);
    } else {
      exams[index] = exam;
    }
    await _saveAll(exams);

    // Persist subject and grade for autocomplete suggestions.
    await _addSubject(exam.subject);
    await _addGrade(exam.grade);
  }

  Future<void> deleteExam(String examId) async {
    final exams = await getExams();
    exams.removeWhere((exam) => exam.id == examId);
    await _saveAll(exams);
  }

  Future<void> _saveAll(List<ExamModel> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
      _storageKey, jsonEncode(exams.map((exam) => exam.toJson()).toList()),
    );
    if (!success) throw Exception('تعذر حفظ الامتحانات على الجهاز');
  }

  // ─── Subject / Grade history ──────────────────────────────────────────────

  /// Returns previously used subject names (for autocomplete suggestions).
  Future<List<String>> getUsedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subjectsKey);
    if (raw == null || raw.isEmpty) return _defaultSubjects;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
      // Merge defaults so a fresh install still has suggestions.
      final merged = {..._defaultSubjects, ...list}.toList();
      return merged;
    } catch (_) {
      return _defaultSubjects;
    }
  }

  /// Returns previously used grade / class names.
  Future<List<String>> getUsedGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gradesKey);
    if (raw == null || raw.isEmpty) return _defaultGrades;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
      final merged = {..._defaultGrades, ...list}.toList();
      return merged;
    } catch (_) {
      return _defaultGrades;
    }
  }

  Future<void> _addSubject(String subject) async {
    if (subject.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getUsedSubjects();
    final updated = {subject.trim(), ...current}.toList();
    await prefs.setString(_subjectsKey, jsonEncode(updated));
  }

  Future<void> _addGrade(String grade) async {
    if (grade.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getUsedGrades();
    final updated = {grade.trim(), ...current}.toList();
    await prefs.setString(_gradesKey, jsonEncode(updated));
  }

  // ─── Defaults ─────────────────────────────────────────────────────────────

  static const List<String> _defaultSubjects = [
    'اللغة العربية',
    'اللغة الإنجليزية',
    'الرياضيات',
    'العلوم',
    'الدراسات الاجتماعية',
    'اللغة الفرنسية',
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'التاريخ',
    'الجغرافيا',
    'التربية الدينية',
    'الحاسب الآلي',
    'التربية الفنية',
    'التربية الرياضية',
  ];

  static const List<String> _defaultGrades = [
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
    'KG1',
    'KG2',
    'Year 1',
    'Year 2',
    'Year 3',
  ];
}
