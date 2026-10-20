
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/exam_model.dart';
import '../services/exam_pdf_service.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

class ExamPreviewScreen extends StatelessWidget {
  final ExamModel exam;

  const ExamPreviewScreen({
    super.key,
    required this.exam,
  });

  static const Color purple = Color(0xFF431599);

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
        SnackBar(content: Text('تعذر تصدير الـ PDF: $e')),
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
        SnackBar(content: Text('تعذر الطباعة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F0F7),
      appBar: AppBar(
        title: const Text('معاينة الامتحان'),
        centerTitle: true,
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  const Divider(
                    color: Colors.black87,
                    thickness: 1.5,
                  ),
                  const SizedBox(height: 12),
                  _buildExamInfo(),
                  if (exam.instructions?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildInstructions(),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'أسئلة الامتحان',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    exam.questions.length,
                    (index) => _buildQuestion(
                      exam.questions[index],
                      index + 1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Colors.black54),
                  const Center(
                    child: Text(
                      'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('تصدير / مشاركة PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _printPdf(context),
                icon: const Icon(Icons.print_outlined),
                label: const Text('طباعة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          exam.teacherName?.isNotEmpty == true
              ? exam.teacherName!
              : 'اسم المدرس',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'امتحان ${exam.title}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'المادة: ${exam.subject}  |  الصف: ${exam.grade}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildExamInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الزمن: ${exam.durationMinutes} دقيقة',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'الدرجة النهائية: ${formatMarks(exam.totalMarks)}',
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: Text('اسم الطالب: ........................')),
              Expanded(child: Text('الفصل: ................')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'تعليمات الامتحان:\n${exam.instructions}',
        style: const TextStyle(fontSize: 14, height: 1.7),
      ),
    );
  }

  Widget _buildQuestion(QuestionModel question, int number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${formatMarks(question.marks)} درجة)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
            padding: const EdgeInsets.only(
              right: 8,
              bottom: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.radio_button_unchecked,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();

      case QuestionType.trueFalse:
        return [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              '○ صح       ○ خطأ',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ];

      case QuestionType.complete:
        return List.generate(
          question.answerLines.clamp(1, 10),
          (_) => const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Divider(
              color: Colors.black54,
              height: 1,
            ),
          ),
        );

      case QuestionType.essay:
        return List.generate(
          question.answerLines.clamp(1, 15),
          (_) => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Divider(
              color: Colors.black54,
              height: 1,
            ),
          ),
        );
    }
  }
}
