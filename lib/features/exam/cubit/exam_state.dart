part of 'exam_cubit.dart';

sealed class ExamState {}
class ExamInitial extends ExamState {}
class ExamLoading extends ExamState {}
class ExamLoaded extends ExamState {
  final List<ExamModel> exams;
  ExamLoaded(this.exams);
}
class ExamDraftChanged extends ExamState {
  final ExamModel exam;
  ExamDraftChanged(this.exam);
}
class ExamDraftCleared extends ExamState {}
class ExamSaving extends ExamState {
  final ExamModel exam;
  ExamSaving(this.exam);
}
class ExamOperationSuccess extends ExamState {
  final String message;
  final List<ExamModel> exams;
  ExamOperationSuccess(this.message, this.exams);
}
class ExamFailure extends ExamState {
  final String errorMessage;
  ExamFailure(this.errorMessage);
}
