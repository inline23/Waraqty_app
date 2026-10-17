import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';

class ExamRepository {
  static const String _storageKey = 'saved_exams';

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
}
