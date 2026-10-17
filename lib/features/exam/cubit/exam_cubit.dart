import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';
import '../repos/exam_repository.dart';

part 'exam_state.dart';

class ExamCubit extends Cubit<ExamState> {
  final ExamRepository repository;
  ExamCubit(this.repository) : super(ExamInitial());

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
