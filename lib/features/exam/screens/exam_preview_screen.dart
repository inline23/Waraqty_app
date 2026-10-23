
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';
import '../services/exam_pdf_service.dart';

class ExamPreviewScreen extends StatelessWidget {
  final ExamModel exam;

  const ExamPreviewScreen({
    super.key,
    required this.exam,
  });

  static const Color purple = Color(0xFF431599);
  static const Color background = Color(0xFFFAF9FF);
  static const Color lavender = Color(0xFFF1ECFA);
  static const Color borderColor = Color(0xFFE5DDF3);
  static const Color textColor = Color(0xFF292333);

  String formatMarks(double marks) {
    return marks == marks.roundToDouble()
        ? marks.toInt().toString()
        : marks.toString();
  }

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final bytes = await ExamPdfService.build(exam);

      await Printing.sharePdf(
        bytes: bytes,
        filename: ExamPdfService.fileName(exam),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر تصدير ملف PDF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Printing.layoutPdf(
        name: ExamPdfService.fileName(exam),
        onLayout: (_) => ExamPdfService.build(exam),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذرت الطباعة: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'معاينة الامتحان',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                children: [
                  _buildPreviewLabel(),
                  const SizedBox(height: 14),
                  _buildPaper(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewLabel() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'معاينة ورقة الامتحان',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${exam.questions.length} أسئلة',
          style: const TextStyle(
            color: Color(0xFF756A88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaper() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 18),
          _buildExamInfo(),
          if (exam.instructions?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _buildInstructions(),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle(
            icon: Icons.list_alt_rounded,
            title: 'أسئلة الامتحان',
          ),
          const SizedBox(height: 12),
          if (exam.questions.isEmpty)
            _buildEmptyQuestions()
          else
            ...List.generate(
              exam.questions.length,
              (index) => _buildQuestion(
                exam.questions[index],
                index + 1,
              ),
            ),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'بسم الله الرحمن الرحيم',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          exam.teacherName?.trim().isNotEmpty == true
              ? exam.teacherName!.trim()
              : 'اسم المدرس',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textColor,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          exam.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: purple,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'المادة: ${exam.subject}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.7,
          ),
        ),
        Text(
          'الصف: ${exam.grade}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildExamInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        border: Border.all(color: const Color(0xFFD6C7F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.schedule_rounded,
                  text: 'الزمن: ${exam.durationMinutes} دقيقة',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoItem(
                  icon: Icons.grade_outlined,
                  text: 'الدرجة: ${formatMarks(exam.totalMarks)}',
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: borderColor, height: 1),
          ),
          _infoItem(
            icon: Icons.person_outline_rounded,
            text: 'اسم الطالب: ................................',
          ),
          const SizedBox(height: 12),
          _infoItem(
            icon: Icons.school_outlined,
            text: 'الفصل: ................................',
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: purple),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lavender.withOpacity(0.55),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: purple,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'تعليمات الامتحان',
                style: TextStyle(
                  color: purple,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exam.instructions!,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: lavender,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple, size: 20),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: purple,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(QuestionModel question, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEAE5F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$number. ${question.text}',
                  style: const TextStyle(
                    color: purple,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${formatMarks(question.marks)} درجة',
                  style: const TextStyle(
                    color: purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildQuestionBody(question),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionBody(QuestionModel question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.radio_button_unchecked,
                  color: Color(0xFF8B8397),
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();

      case QuestionType.trueFalse:
        return [
          const Row(
            children: [
              Expanded(
                child: _AnswerOption(label: 'صح'),
              ),
              Expanded(
                child: _AnswerOption(label: 'خطأ'),
              ),
            ],
          ),
        ];

      case QuestionType.complete:
      case QuestionType.essay:
        return List.generate(
          question.answerLines.clamp(
            1,
            question.type == QuestionType.essay ? 15 : 10,
          ),
          (_) => const Padding(
            padding: EdgeInsets.only(top: 23),
            child: Divider(
              color: Color(0xFFBDB5C9),
              height: 1,
            ),
          ),
        );
    }
  }

  Widget _buildEmptyQuestions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'لم تتم إضافة أسئلة إلى هذا الامتحان بعد.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: borderColor),
        const SizedBox(height: 8),
        const Text(
          'انتهت الأسئلة',
          style: TextStyle(
            color: purple,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'مع أطيب التمنيات بالتوفيق والنجاح',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text(
                  'تصدير / مشاركة PDF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _printPdf(context),
                icon: const Icon(Icons.print_outlined),
                label: const Text(
                  'طباعة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                  side: const BorderSide(
                    color: Color(0xFFBBA7E4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String label;

  const _AnswerOption({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.radio_button_unchecked,
          color: Color(0xFF8B8397),
          size: 17,
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B8397),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
