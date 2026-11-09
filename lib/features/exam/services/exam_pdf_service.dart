import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam_model.dart';
import '../models/exam_print_settings.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

class ExamPdfService {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static const double _fontSize = 10.5;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    _bold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );
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

  /// Builds the PDF bytes. If [settings] is null the classic template
  /// with default options is used (backward compatible).
  static Future<Uint8List> build(
    ExamModel exam, [
    ExamPrintSettings? settings,
  ]) async {
    await _loadFonts();

    final s = settings ?? const ExamPrintSettings();

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

    final headerPdf = _toPdfColor(s.headerColor);
    final lightPdf = _lighten(headerPdf);
    final borderPdf = PdfColor(215 / 255, 205 / 255, 232 / 255);

    // Decode logo if provided.
    pw.ImageProvider? logoImage;
    if (s.logoImageBytes != null) {
      try {
        logoImage = pw.MemoryImage(s.logoImageBytes!);
      } catch (_) {
        logoImage = null;
      }
    }

    final doc = pw.Document(
      title: exam.title,
      author: exam.teacherName ?? 'ورقتي',
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.fromLTRB(32, 25, 32, 28),

        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return _continuationHeader(exam, base, bold, headerPdf, borderPdf);
        },

        footer: (context) => _footer(context, base, bold, borderPdf),

        build: (context) => [
          // Page 1 header (varies by template).
          _buildTemplateHeader(
            exam: exam,
            settings: s,
            base: base,
            bold: bold,
            headerPdf: headerPdf,
            lightPdf: lightPdf,
            borderPdf: borderPdf,
            logoImage: logoImage,
          ),

          pw.SizedBox(height: 10),

          if (s.showStudentInfo) ...[
            _info(exam, s, base, bold, headerPdf, lightPdf, borderPdf),
            pw.SizedBox(height: 8),
          ],

          if (exam.instructions?.trim().isNotEmpty == true) ...[
            _instructions(exam, base, bold, headerPdf),
            pw.SizedBox(height: 8),
          ],

          pw.SizedBox(height: 4),

          _sectionHeading('أسئلة الامتحان', bold, headerPdf, lightPdf),

          pw.SizedBox(height: 8),

          for (var i = 0; i < exam.questions.length; i++)
            _question(exam.questions[i], i + 1, base, bold, headerPdf),

          pw.SizedBox(height: 8),

          _closing(bold, headerPdf, s.showDecorations),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Template Headers ────────────────────────────────────────────────────

  static pw.Widget _buildTemplateHeader({
    required ExamModel exam,
    required ExamPrintSettings settings,
    required pw.TextStyle base,
    required pw.TextStyle bold,
    required PdfColor headerPdf,
    required PdfColor lightPdf,
    required PdfColor borderPdf,
    pw.ImageProvider? logoImage,
  }) {
    switch (settings.template) {
      case ExamTemplate.classic:
        return _headerClassic(
          exam: exam,
          settings: settings,
          base: base,
          bold: bold,
          headerPdf: headerPdf,
          lightPdf: lightPdf,
          borderPdf: borderPdf,
          logoImage: logoImage,
        );
      case ExamTemplate.modern:
        return _headerModern(
          exam: exam,
          settings: settings,
          base: base,
          bold: bold,
          headerPdf: headerPdf,
          lightPdf: lightPdf,
          logoImage: logoImage,
        );
      case ExamTemplate.official:
        return _headerOfficial(
          exam: exam,
          settings: settings,
          base: base,
          bold: bold,
          headerPdf: headerPdf,
          lightPdf: lightPdf,
          borderPdf: borderPdf,
          logoImage: logoImage,
        );
    }
  }

  // ── Classic Template ──────────────────────────────────────────────────────

  static pw.Widget _headerClassic({
    required ExamModel exam,
    required ExamPrintSettings settings,
    required pw.TextStyle base,
    required pw.TextStyle bold,
    required PdfColor headerPdf,
    required PdfColor lightPdf,
    required PdfColor borderPdf,
    pw.ImageProvider? logoImage,
  }) {
    final teacher = settings.showTeacherName &&
            exam.teacherName?.trim().isNotEmpty == true
        ? exam.teacherName!.trim()
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Teacher name top-right + logo if any
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Image(logoImage, width: 50, height: 50, fit: pw.BoxFit.contain)
            else
              pw.SizedBox(width: 50),
            pw.Expanded(child: pw.SizedBox()),
            if (teacher != null)
              pw.Text(teacher,
                  style: base.copyWith(
                      fontSize: 9, color: PdfColors.grey700)),
          ],
        ),

        if (settings.schoolName?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              settings.schoolName!,
              style: bold.copyWith(fontSize: 11, color: headerPdf),
            ),
          ),
        ],

        if (settings.headerText?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              settings.headerText!,
              style: base.copyWith(fontSize: 9),
            ),
          ),
        ],

        if (settings.showBazmala) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'بسم الله الرحمن الرحيم',
              style: base.copyWith(fontSize: 10),
            ),
          ),
        ],

        pw.SizedBox(height: 5),

        pw.Center(
          child: pw.Text(
            exam.title,
            style: bold.copyWith(fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 4),

        if (settings.showSubjectGrade)
          pw.Center(
            child: pw.Text(
              'المادة: ${exam.subject}   |   الصف: ${exam.grade}',
              style: base.copyWith(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),

        pw.SizedBox(height: 8),

        if (settings.showDecorations)
          pw.Container(
            height: 2,
            decoration: pw.BoxDecoration(
              color: headerPdf,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  // ── Modern Template ───────────────────────────────────────────────────────

  static pw.Widget _headerModern({
    required ExamModel exam,
    required ExamPrintSettings settings,
    required pw.TextStyle base,
    required pw.TextStyle bold,
    required PdfColor headerPdf,
    required PdfColor lightPdf,
    pw.ImageProvider? logoImage,
  }) {
    final teacher = settings.showTeacherName &&
            exam.teacherName?.trim().isNotEmpty == true
        ? exam.teacherName!.trim()
        : null;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightPdf,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Image(logoImage,
                    width: 44, height: 44, fit: pw.BoxFit.contain),
                pw.SizedBox(width: 10),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (settings.schoolName?.isNotEmpty == true)
                      pw.Text(
                        settings.schoolName!,
                        style: bold.copyWith(fontSize: 10, color: headerPdf),
                      ),
                    if (settings.headerText?.isNotEmpty == true)
                      pw.Text(
                        settings.headerText!,
                        style: base.copyWith(fontSize: 8),
                      ),
                  ],
                ),
              ),
              if (teacher != null)
                pw.Text(teacher,
                    style: base.copyWith(
                        fontSize: 8, color: PdfColors.grey700)),
            ],
          ),

          pw.SizedBox(height: 10),

          pw.Container(
            height: 1,
            color: headerPdf,
          ),

          pw.SizedBox(height: 8),

          if (settings.showBazmala)
            pw.Center(
              child: pw.Text(
                'بسم الله الرحمن الرحيم',
                style: base.copyWith(fontSize: 9, color: PdfColors.grey700),
              ),
            ),

          if (settings.showBazmala) pw.SizedBox(height: 4),

          pw.Center(
            child: pw.Text(
              exam.title,
              style: bold.copyWith(fontSize: 15, color: headerPdf),
              textAlign: pw.TextAlign.center,
            ),
          ),

          if (settings.showSubjectGrade) ...[
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                '${exam.subject} — ${exam.grade}',
                style: base.copyWith(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Official Template ─────────────────────────────────────────────────────

  static pw.Widget _headerOfficial({
    required ExamModel exam,
    required ExamPrintSettings settings,
    required pw.TextStyle base,
    required pw.TextStyle bold,
    required PdfColor headerPdf,
    required PdfColor lightPdf,
    required PdfColor borderPdf,
    pw.ImageProvider? logoImage,
  }) {
    final teacher = settings.showTeacherName &&
            exam.teacherName?.trim().isNotEmpty == true
        ? exam.teacherName!.trim()
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Top bordered header bar
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: headerPdf, width: 1.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo box
              pw.Container(
                width: 55,
                height: 55,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderPdf),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: logoImage != null
                    ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'الشعار',
                          style: base.copyWith(
                              fontSize: 7, color: PdfColors.grey500),
                        ),
                      ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (settings.schoolName?.isNotEmpty == true)
                      pw.Text(
                        settings.schoolName!,
                        style: bold.copyWith(fontSize: 12, color: headerPdf),
                        textAlign: pw.TextAlign.center,
                      ),
                    if (settings.headerText?.isNotEmpty == true) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        settings.headerText!,
                        style: base.copyWith(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                    if (settings.showBazmala) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'بسم الله الرحمن الرحيم',
                        style: base.copyWith(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              // Right side – teacher name
              pw.SizedBox(
                width: 55,
                child: teacher != null
                    ? pw.Text(
                        teacher,
                        style: base.copyWith(
                            fontSize: 8, color: PdfColors.grey700),
                        textAlign: pw.TextAlign.left,
                      )
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // Exam title + subject/grade
        pw.Center(
          child: pw.Text(
            exam.title,
            style: bold.copyWith(fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        ),

        if (settings.showSubjectGrade) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'المادة: ${exam.subject}   |   الصف: ${exam.grade}',
              style: base.copyWith(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],

        pw.SizedBox(height: 6),

        if (settings.showDecorations)
          pw.Container(
            height: 1.5,
            decoration: pw.BoxDecoration(
              color: headerPdf,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  // ─── Shared Components ────────────────────────────────────────────────────

  static pw.Widget _continuationHeader(
    ExamModel exam,
    pw.TextStyle base,
    pw.TextStyle bold,
    PdfColor headerPdf,
    PdfColor borderPdf,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: borderPdf, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              exam.title,
              style: bold.copyWith(fontSize: 9, color: headerPdf),
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
  }

  static pw.Widget _footer(
    pw.Context context,
    pw.TextStyle base,
    pw.TextStyle bold,
    PdfColor borderPdf,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderPdf, width: 0.8)),
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
  }

  static pw.Widget _info(
    ExamModel exam,
    ExamPrintSettings settings,
    pw.TextStyle base,
    pw.TextStyle bold,
    PdfColor headerPdf,
    PdfColor lightPdf,
    PdfColor borderPdf,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: lightPdf,
        border: pw.Border.all(color: borderPdf, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (settings.showDurationMarks)
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

          if (settings.showDurationMarks) pw.SizedBox(height: 7),

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
    PdfColor headerPdf,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border(
            right: pw.BorderSide(color: headerPdf, width: 2.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'تعليمات الامتحان',
            style: bold.copyWith(fontSize: 9.5, color: headerPdf),
          ),
          pw.SizedBox(height: 3),
          pw.Text(exam.instructions!.trim(), style: base.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeading(
    String title,
    pw.TextStyle bold,
    PdfColor headerPdf,
    PdfColor lightPdf,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: pw.BoxDecoration(
        color: lightPdf,
        border: pw.Border(right: pw.BorderSide(color: headerPdf, width: 3)),
      ),
      child: pw.Text(title,
          style: bold.copyWith(fontSize: 10.5, color: headerPdf)),
    );
  }

  static pw.Widget _question(
    QuestionModel question,
    int number,
    pw.TextStyle base,
    pw.TextStyle bold,
    PdfColor headerPdf,
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
                style: bold.copyWith(fontSize: 8.5, color: headerPdf),
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

  static pw.Widget _closing(
      pw.TextStyle bold, PdfColor headerPdf, bool showDecorations) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: showDecorations
          ? pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                    color: PdfColor(215 / 255, 205 / 255, 232 / 255),
                    width: 0.8),
              ),
            )
          : null,
      child: pw.Center(
        child: pw.Text(
          'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق والنجاح',
          style: bold.copyWith(fontSize: 9, color: headerPdf),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  // ─── Color Helpers ────────────────────────────────────────────────────────

  static PdfColor _toPdfColor(Color color) {
    return PdfColor(
      color.r / 255.0,
      color.g / 255.0,
      color.b / 255.0,
    );
  }

  static PdfColor _lighten(PdfColor color) {
    return PdfColor(
      color.red + (1.0 - color.red) * 0.88,
      color.green + (1.0 - color.green) * 0.88,
      color.blue + (1.0 - color.blue) * 0.88,
    );
  }
}
