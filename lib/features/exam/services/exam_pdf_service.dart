import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

/// يبني ملف PDF لورقة الامتحان (A4، عربي، RTL).
///
/// يحتاج خطوط عربية داخل assets:
///   assets/fonts/Cairo-Regular.ttf
///   assets/fonts/Cairo-Bold.ttf
class ExamPdfService {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    _bold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );
  }

  static String _marks(double marks) =>
      marks == marks.roundToDouble() ? marks.toInt().toString() : marks.toString();

  /// اسم ملف مناسب للمشاركة/الحفظ.
  static String fileName(ExamModel exam) {
    final safe = exam.title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${safe.isEmpty ? 'exam' : safe}.pdf';
  }

  static Future<Uint8List> build(ExamModel exam) async {
    await _loadFonts();

    final base = pw.TextStyle(font: _regular, fontBold: _bold, fontSize: 12, lineSpacing: 3);
    final bold = base.copyWith(font: _bold, fontWeight: pw.FontWeight.bold);

    final doc = pw.Document(
      title: exam.title,
      author: exam.teacherName ?? 'ورقتي',
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (_) => pw.SizedBox(),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            style: base.copyWith(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (ctx) => [
          _header(exam, base, bold),
          pw.SizedBox(height: 10),
          _info(exam, base, bold),
          if (exam.instructions?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 10),
            _instructions(exam, base, bold),
          ],
          pw.SizedBox(height: 16),
          pw.Text('أسئلة الامتحان', style: bold.copyWith(fontSize: 15)),
          pw.SizedBox(height: 8),
          for (var i = 0; i < exam.questions.length; i++)
            _question(exam.questions[i], i + 1, base, bold),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey700),
          pw.Center(
            child: pw.Text(
              'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق',
              style: bold.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(ExamModel exam, pw.TextStyle base, pw.TextStyle bold) {
    final teacher = exam.teacherName?.trim().isNotEmpty == true ? exam.teacherName! : 'اسم المدرس';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('بسم الله الرحمن الرحيم', style: bold.copyWith(fontSize: 11)),
        pw.SizedBox(height: 6),
        pw.Text(teacher, style: bold.copyWith(fontSize: 18)),
        pw.SizedBox(height: 6),
        pw.Text('امتحان ${exam.title}', style: bold.copyWith(fontSize: 15)),
        pw.SizedBox(height: 3),
        pw.Text('المادة: ${exam.subject}  |  الصف: ${exam.grade}', style: base.copyWith(fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.5, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _info(ExamModel exam, pw.TextStyle base, pw.TextStyle bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey800)),
      child: pw.Column(
        children: [
          pw.Row(children: [
            pw.Expanded(child: pw.Text('الزمن: ${exam.durationMinutes} دقيقة', style: bold)),
            pw.Expanded(
              child: pw.Text('الدرجة النهائية: ${_marks(exam.totalMarks)}', style: bold),
            ),
          ]),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('اسم الطالب: ........................', style: base)),
            pw.Expanded(child: pw.Text('الفصل: ................', style: base)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _instructions(ExamModel exam, pw.TextStyle base, pw.TextStyle bold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('تعليمات الامتحان:', style: bold),
          pw.SizedBox(height: 3),
          pw.Text(exam.instructions!.trim(), style: base),
        ],
      ),
    );
  }

  static pw.Widget _question(
    QuestionModel q,
    int number,
    pw.TextStyle base,
    pw.TextStyle bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text('$number. ${q.text}', style: bold.copyWith(fontSize: 13)),
              ),
              pw.SizedBox(width: 8),
              pw.Text('(${_marks(q.marks)} درجة)', style: base.copyWith(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 6),
          ..._body(q, base),
        ],
      ),
    );
  }

  static List<pw.Widget> _body(QuestionModel q, pw.TextStyle base) {
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];
    switch (q.type) {
      case QuestionType.multipleChoice:
        return [
          for (var i = 0; i < q.options.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8, bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(top: 3),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.grey800),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text('${letters[i % letters.length]}) ${q.options[i]}', style: base),
                  ),
                ],
              ),
            ),
        ];

      case QuestionType.trueFalse:
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 8),
            child: pw.Row(children: [
              _circle(),
              pw.SizedBox(width: 5),
              pw.Text('صح', style: base),
              pw.SizedBox(width: 24),
              _circle(),
              pw.SizedBox(width: 5),
              pw.Text('خطأ', style: base),
            ]),
          ),
        ];

      case QuestionType.complete:
        return _lines(q.answerLines.clamp(1, 10), 18);

      case QuestionType.essay:
        return _lines(q.answerLines.clamp(1, 15), 22);
    }
  }

  static pw.Widget _circle() => pw.Container(
        width: 10,
        height: 10,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: PdfColors.grey800),
        ),
      );

  static List<pw.Widget> _lines(int count, double gap) => List.generate(
        count,
        (_) => pw.Container(
          height: gap,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.6)),
          ),
        ),
      );
}
