import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

class ExamPdfService {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static final PdfColor _purple = PdfColor(67 / 255, 21 / 255, 153 / 255);

  static final PdfColor _lightPurple = PdfColor(
    244 / 255,
    239 / 255,
    252 / 255,
  );

  static final PdfColor _border = PdfColor(215 / 255, 205 / 255, 232 / 255);

  static const double _fontSize = 10.5;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static String _marks(double marks) {
    return marks == marks.roundToDouble()
        ? marks.toInt().toString()
        : marks.toString();
  }

  static String fileName(ExamModel exam) {
    final safe = exam.title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return '${safe.isEmpty ? 'Waraqty_Exam' : safe}.pdf';
  }

  static Future<Uint8List> build(ExamModel exam) async {
    await _loadFonts();

    final base = pw.TextStyle(
      font: _regular,
      fontSize: _fontSize,
      lineSpacing: 1.5,
      color: PdfColors.black,
    );

    final bold = pw.TextStyle(
      font: _bold,
      fontSize: _fontSize,
      lineSpacing: 1.5,
      color: PdfColors.black,
    );

    final doc = pw.Document(
      title: exam.title,
      author: exam.teacherName ?? 'ورقتي',
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,

        // مساحة أكبر للأسئلة مع هوامش طباعة آمنة.
        margin: const pw.EdgeInsets.fromLTRB(32, 25, 32, 28),

        // ترويسة الصفحات التالية.
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _border, width: 0.8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    exam.title,
                    style: bold.copyWith(fontSize: 9, color: _purple),
                    maxLines: 1,
                  ),
                ),
                pw.Text(
                  '${exam.subject} - ${exam.grade}',
                  style: base.copyWith(fontSize: 8),
                ),
              ],
            ),
          );
        },

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ورقتي | مع أطيب التمنيات بالتوفيق',
                  style: base.copyWith(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: base.copyWith(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },

        build: (context) => [
          _header(exam, base, bold),
          pw.SizedBox(height: 10),

          _info(exam, base, bold),

          if (exam.instructions?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            _instructions(exam, base, bold),
          ],

          pw.SizedBox(height: 12),

          _sectionHeading('أسئلة الامتحان'),

          pw.SizedBox(height: 8),

          for (var i = 0; i < exam.questions.length; i++)
            _question(exam.questions[i], i + 1, base, bold),

          pw.SizedBox(height: 8),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _border, width: 0.8)),
            ),
            child: pw.Center(
              child: pw.Text(
                'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق والنجاح',
                style: bold.copyWith(fontSize: 9, color: _purple),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(
    ExamModel exam,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    final teacher = exam.teacherName?.trim().isNotEmpty == true
        ? exam.teacherName!.trim()
        : 'اسم المدرس';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            'بسم الله الرحمن الرحيم',
            style: base.copyWith(fontSize: 10),
          ),
        ),

        pw.SizedBox(height: 5),

        pw.Center(
          child: pw.Text(
            teacher,
            style: bold.copyWith(fontSize: 17, color: _purple),
          ),
        ),

        pw.SizedBox(height: 4),

        pw.Center(
          child: pw.Text(
            exam.title,
            style: bold.copyWith(fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 4),

        pw.Center(
          child: pw.Text(
            'المادة: ${exam.subject}   |   الصف: ${exam.grade}',
            style: base.copyWith(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Container(
          height: 2,
          decoration: pw.BoxDecoration(
            color: _purple,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  static pw.Widget _info(ExamModel exam, pw.TextStyle base, pw.TextStyle bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _lightPurple,
        border: pw.Border.all(color: _border, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'الزمن: ${exam.durationMinutes} دقيقة',
                  style: bold.copyWith(fontSize: 9.5),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'الدرجة النهائية: ${_marks(exam.totalMarks)}',
                  style: bold.copyWith(fontSize: 9.5),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 7),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'اسم الطالب: ................................',
                  style: base.copyWith(fontSize: 9),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'الفصل: ................',
                  style: base.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _instructions(
    ExamModel exam,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border(right: pw.BorderSide(color: _purple, width: 2.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'تعليمات الامتحان',
            style: bold.copyWith(fontSize: 9.5, color: _purple),
          ),
          pw.SizedBox(height: 3),
          pw.Text(exam.instructions!.trim(), style: base.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeading(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _lightPurple,
        border: pw.Border(right: pw.BorderSide(color: _purple, width: 3)),
      ),
    );
  }

  static pw.Widget _question(
    QuestionModel question,
    int number,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '$number. ${question.text}',
                  style: bold.copyWith(fontSize: 10.5),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                '(${_marks(question.marks)} درجة)',
                style: bold.copyWith(fontSize: 8.5, color: _purple),
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          ..._body(question, base),
        ],
      ),
    );
  }

  static List<pw.Widget> _body(QuestionModel question, pw.TextStyle base) {
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];

    switch (question.type) {
      case QuestionType.multipleChoice:
        return [
          for (var i = 0; i < question.options.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 9, bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _circle(size: 8),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Text(
                      '${letters[i % letters.length]}) ${question.options[i]}',
                      style: base.copyWith(fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ),
        ];

      case QuestionType.trueFalse:
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 9),
            child: pw.Row(
              children: [
                _circle(size: 8),
                pw.SizedBox(width: 4),
                pw.Text('صح', style: base.copyWith(fontSize: 9.5)),
                pw.SizedBox(width: 22),
                _circle(size: 8),
                pw.SizedBox(width: 4),
                pw.Text('خطأ', style: base.copyWith(fontSize: 9.5)),
              ],
            ),
          ),
        ];

      case QuestionType.complete:
        return _lines(question.answerLines.clamp(1, 10), 15);

      case QuestionType.essay:
        return _lines(question.answerLines.clamp(1, 15), 19);
    }
  }

  static pw.Widget _circle({double size = 9}) {
    return pw.Container(
      width: size,
      height: size,
      margin: const pw.EdgeInsets.only(top: 3),
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
      ),
    );
  }

  static List<pw.Widget> _lines(int count, double height) {
    return List.generate(
      count,
      (_) => pw.Container(
        height: height,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
          ),
        ),
      ),
    );
  }
}
