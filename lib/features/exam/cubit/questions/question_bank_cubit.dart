import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/exam/models/bank_question_model.dart';
import 'package:waraqty_app/features/exam/models/question_model.dart';
import 'package:waraqty_app/features/exam/repos/exam_repository.dart';
import 'package:waraqty_app/features/exam/repos/question_bank_repository.dart';


part 'question_bank_state.dart';

class QuestionBankCubit extends Cubit<QuestionBankState> {
  final QuestionBankRepository repository;
  final ExamRepository examRepository;

  QuestionBankCubit(this.repository, this.examRepository)
    : super(QuestionBankInitial());

  List<BankQuestion> items = [];

  Future<void> load() async {
    if (items.isEmpty) emit(QuestionBankLoading());
    try {
      if (!await repository.isSeeded()) {
        final exams = await examRepository.getExams();
        await repository.seedFromExams(exams);
      }
      items = await repository.getAll();
      emit(QuestionBankLoaded(List.unmodifiable(items)));
    } catch (e) {
      emit(QuestionBankFailure('تعذر تحميل بنك الأسئلة: $e'));
    }
  }

  /// حفظ سؤال واحد في البنك (زر "إضافة السؤال إلى بنك الأسئلة").
  /// يرجع true لو السؤال اتضاف جديد، false لو كان موجود بالفعل.
  Future<bool> saveQuestion(
    QuestionModel question, {
    required String subject,
    required String grade,
  }) async {
    final before = (await repository.getAll()).length;
    await repository.addQuestions([question], subject: subject, grade: grade);
    items = await repository.getAll();
    emit(QuestionBankLoaded(List.unmodifiable(items)));
    return items.length > before;
  }

  Future<void> updateQuestion(
    String id,
    QuestionModel question, {
    String? subject,
    String? grade,
  }) async {
    try {
      await repository.update(id, question, subject: subject, grade: grade);
      items = await repository.getAll();
      emit(QuestionBankLoaded(List.unmodifiable(items)));
    } catch (e) {
      emit(QuestionBankFailure('تعذر تعديل السؤال: $e'));
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.delete(id);
      items = await repository.getAll();
      emit(QuestionBankLoaded(List.unmodifiable(items)));
    } catch (e) {
      emit(QuestionBankFailure('تعذر حذف السؤال: $e'));
    }
  }
}
