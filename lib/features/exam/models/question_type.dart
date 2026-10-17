enum QuestionType {
  multipleChoice,
  complete,
  trueFalse,
  essay;

  String get arabicName {
    switch (this) {
      case QuestionType.multipleChoice: return 'اختيار من متعدد';
      case QuestionType.complete: return 'أكمل العبارات الآتية';
      case QuestionType.trueFalse: return 'صح أم خطأ';
      case QuestionType.essay: return 'سؤال مقالي';
    }
  }
}
