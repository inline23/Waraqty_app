part of 'question_bank_cubit.dart';

sealed class QuestionBankState {}

class QuestionBankInitial extends QuestionBankState {}

class QuestionBankLoading extends QuestionBankState {}

class QuestionBankLoaded extends QuestionBankState {
  final List<BankQuestion> items;
  QuestionBankLoaded(this.items);
}

class QuestionBankFailure extends QuestionBankState {
  final String message;
  QuestionBankFailure(this.message);
}
