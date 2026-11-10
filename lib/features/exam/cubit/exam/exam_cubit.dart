import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/exam/models/bank_question_model.dart';
import 'package:waraqty_app/features/exam/models/exam_model.dart';
import 'package:waraqty_app/features/exam/models/question_model.dart';
import 'package:waraqty_app/features/exam/repos/exam_repository.dart';
import 'package:waraqty_app/features/exam/repos/question_bank_repository.dart';


part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  final ExamRepository repository;
  final QuestionBankRepository? bankRepository;
  ExamCubit(this.repository, {this.bankRepository}) : super(ExamInitial());

  List<ExamModel> exams = [];
  ExamModel? draft;
  bool isSaving = false;

  Future<void> fetchExams() async {
    emit(ExamLoading());
    try {
      exams = await repository.getExams();
      emit(ExamLoaded(List.unmodifiable(exams)));
    } catch (e) {
      emit(ExamFailure('تعذر تحميل الامتحانات: $e'));
    }
  }

  void startDraft({
    required String title,
    required String subject,
    required String grade,
    String? teacherName,
    required int durationMinutes,
    String? instructions,
  }) {
    final now = DateTime.now();
    draft = ExamModel(
      id: 'exam_${now.microsecondsSinceEpoch}',
      title: title.trim(),
      subject: subject.trim(),
      grade: grade.trim(),
      teacherName: teacherName?.trim().isEmpty == true ? null : teacherName?.trim(),
      durationMinutes: durationMinutes,
      instructions: instructions?.trim().isEmpty == true ? null : instructions?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    emit(ExamDraftChanged(draft!));
  }

  void editDraftDetails({
    required String title,
    required String subject,
    required String grade,
    String? teacherName,
    required int durationMinutes,
    String? instructions,
  }) {
    final current = draft;
    if (current == null) return;
    draft = current.copyWith(
      title: title.trim(),
      subject: subject.trim(),
      grade: grade.trim(),
      teacherName: teacherName?.trim().isEmpty == true ? null : teacherName?.trim(),
      durationMinutes: durationMinutes,
      instructions: instructions?.trim().isEmpty == true ? null : instructions?.trim(),
      updatedAt: DateTime.now(),
    );
    emit(ExamDraftChanged(draft!));
  }

  void addQuestion(QuestionModel question) {
    final current = draft;
    if (current == null) return;
    draft = current.copyWith(
      questions: [...current.questions, question],
      updatedAt: DateTime.now(),
    );
    emit(ExamDraftChanged(draft!));
  }

  /// إضافة أسئلة من بنك الأسئلة للمسودة كنسخ مستقلة (id جديد لكل نسخة)،
  /// فأي تعديل/حذف في الامتحان أو في البنك لا يؤثر على الطرف التاني.
  /// بترجع عدد الأسئلة اللي اتضافت فعلًا (بتتجاهل المكرر الموجود في الامتحان).
  int addBankQuestions(List<BankQuestion> items) {
    final current = draft;
    if (current == null || items.isEmpty) return 0;
    final existing = current.questions.map((q) => q.signature).toSet();
    final now = DateTime.now();
    final copies = <QuestionModel>[];
    for (final item in items) {
      if (!existing.add(item.signature)) continue;
      copies.add(
        item.question.copyWith(
          id: 'question_${now.microsecondsSinceEpoch}_${copies.length}',
          options: List<String>.from(item.question.options),
          createdAt: now,
        ),
      );
    }
    if (copies.isEmpty) return 0;
    draft = current.copyWith(
      questions: [...current.questions, ...copies],
      updatedAt: now,
    );
    emit(ExamDraftChanged(draft!));
    return copies.length;
  }

  void updateQuestion(QuestionModel question) {
    final current = draft;
    if (current == null) return;
    draft = current.copyWith(
      questions: current.questions.map((q) => q.id == question.id ? question : q).toList(),
      updatedAt: DateTime.now(),
    );
    emit(ExamDraftChanged(draft!));
  }

  void deleteQuestion(String questionId) {
    final current = draft;
    if (current == null) return;
    draft = current.copyWith(
      questions: current.questions.where((q) => q.id != questionId).toList(),
      updatedAt: DateTime.now(),
    );
    emit(ExamDraftChanged(draft!));
  }

  void clearDraft() {
    draft = null;
    emit(ExamDraftCleared());
  }

  /// تحميل امتحان محفوظ في الـ draft لبدء التعديل عليه.
  void loadExamForEdit(ExamModel exam) {
    draft = exam;
    emit(ExamDraftChanged(draft!));
  }

  /// إعادة ترتيب الأسئلة (Drag & Drop) — oldIndex → newIndex.
  void reorderQuestion(int oldIndex, int newIndex) {
    final current = draft;
    if (current == null) return;
    final list = List<QuestionModel>.from(current.questions);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    draft = current.copyWith(questions: list, updatedAt: DateTime.now());
    emit(ExamDraftChanged(draft!));
  }

  Future<void> saveDraft() async {
    final current = draft;
    if (current == null) {
      emit(ExamFailure('لا يوجد امتحان لحفظه'));
      return;
    }
    if (current.questions.isEmpty) {
      emit(ExamFailure('أضف سؤالًا واحدًا على الأقل قبل حفظ الامتحان'));
      return;
    }
    isSaving = true;
    emit(ExamSaving(current));
    try {
      await repository.saveExam(current.copyWith(updatedAt: DateTime.now()));
      exams = await repository.getExams();
      // حفظ أسئلة الامتحان في بنك الأسئلة (بدون تكرار). فشل البنك لا يمنع حفظ الامتحان.
      try {
        await bankRepository?.addQuestions(
          current.questions,
          subject: current.subject,
          grade: current.grade,
        );
      } catch (_) {}
      isSaving = false;
      emit(ExamOperationSuccess('تم حفظ الامتحان بنجاح', List.unmodifiable(exams)));
    } catch (e) {
      isSaving = false;
      emit(ExamFailure('تعذر حفظ الامتحان: $e'));
    }
  }

  Future<void> createExam(ExamModel exam) async {
    try {
      await repository.saveExam(exam);
      exams = await repository.getExams();
      emit(ExamOperationSuccess('تم حفظ الامتحان بنجاح', List.unmodifiable(exams)));
    } catch (e) {
      emit(ExamFailure(e.toString()));
    }
  }

  Future<void> updateExam(ExamModel exam) => createExam(exam.copyWith(updatedAt: DateTime.now()));

  Future<void> deleteExam(String examId) async {
    emit(ExamLoading());
    try {
      await repository.deleteExam(examId);
      exams = await repository.getExams();
      emit(ExamOperationSuccess('تم حذف الامتحان بنجاح', List.unmodifiable(exams)));
    } catch (e) {
      emit(ExamFailure(e.toString()));
    }
  }
}
