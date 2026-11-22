import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/exam_model.dart';
import '../models/exam_print_settings.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

/// تصدير الامتحان PDF بثلاثة قوالب مختلفة فعلًا:
///  - classic : ورقة امتحان تقليدية (خطوط مزدوجة، خلايا بيانات، أسئلة بسيطة).
///  - modern  : بانر ملوّن كامل العرض، بادجات، أسئلة بأرقام دائرية.
///  - official: إطار حول الصفحة، رأس بثلاثة أعمدة، جدول بيانات، "س١" وخانة درجة.
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

  static String _marks(double marks) => marks == marks.roundToDouble()
      ? marks.toInt().toString()
      : marks.toString();

  static String fileName(ExamModel exam) {
    final safe = exam.title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${safe.isEmpty ? 'Waraqty_Exam' : safe}.pdf';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  static Future<Uint8List> build(
    ExamModel exam, [
    ExamPrintSettings? settings,
  ]) async {
    await _loadFonts();
    final s = settings ?? const ExamPrintSettings();

    final t = _Theme(
      base: pw.TextStyle(
        font: _regular,
        fontSize: 10.5,
        lineSpacing: 1.5,
        color: PdfColors.black,
      ),
      bold: pw.TextStyle(
        font: _bold,
        fontSize: 10.5,
        lineSpacing: 1.5,
        color: PdfColors.black,
      ),
      main: _toPdfColor(s.headerColor),
      light: _lighten(_toPdfColor(s.headerColor), 0.90),
      softer: _lighten(_toPdfColor(s.headerColor), 0.80),
      border: PdfColor(0.82, 0.80, 0.88),
    );

    pw.ImageProvider? logo;
    if (s.logoImageBytes != null) {
      try {
        logo = pw.MemoryImage(s.logoImageBytes!);
      } catch (_) {
        logo = null;
      }
    }

    final teacher =
        s.showTeacherName && exam.teacherName?.trim().isNotEmpty == true
            ? exam.teacherName!.trim()
            : null;

    final doc = pw.Document(
      title: exam.title,
      author: exam.teacherName ?? 'ورقتي',
    );

    final official = s.template == ExamTemplate.official;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.fromLTRB(
            official ? 38 : 32,
            official ? 34 : 26,
            official ? 38 : 32,
            official ? 34 : 28,
          ),
          theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
          buildBackground: official && s.showDecorations
              ? (ctx) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(16),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: t.main, width: 1.4),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(2.5),
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: t.main, width: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
              : null,
        ),
        header: (ctx) =>
            ctx.pageNumber == 1 ? pw.SizedBox() : _continuationHeader(exam, t),
        footer: (ctx) => _footer(ctx, t, official),
        build: (ctx) => [
          _header(exam, s, t, teacher, logo),
          pw.SizedBox(height: 10),
          if (s.showDurationMarks || s.showStudentInfo) ...[
            _info(exam, s, t),
            pw.SizedBox(height: 10),
          ],
          if (exam.instructions?.trim().isNotEmpty == true) ...[
            _instructions(exam, s, t),
            pw.SizedBox(height: 10),
          ],
          _sectionHeading('أسئلة الامتحان', s, t),
          pw.SizedBox(height: 10),
          for (var i = 0; i < exam.questions.length; i++)
            _question(exam.questions[i], i + 1, s, t),
          pw.SizedBox(height: 6),
          _closing(exam, s, t),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Headers ──────────────────────────────────────────────────────────────

  static pw.Widget _header(
    ExamModel exam,
    ExamPrintSettings s,
    _Theme t,
    String? teacher,
    pw.ImageProvider? logo,
  ) {
    switch (s.template) {
      case ExamTemplate.classic:
        return _headerClassic(exam, s, t, teacher, logo);
      case ExamTemplate.modern:
        return _headerModern(exam, s, t, teacher, logo);
      case ExamTemplate.official:
        return _headerOfficial(exam, s, t, teacher, logo);
    }
  }

  /// كلاسيك: خط مزدوج علوي، صف (شعار | مدرسة | مدرس)، عنوان في المنتصف.
  static pw.Widget _headerClassic(
    ExamModel exam,
    ExamPrintSettings s,
    _Theme t,
    String? teacher,
    pw.ImageProvider? logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (s.showDecorations) ...[
          _rule(t.main, 2.4),
          pw.SizedBox(height: 2),
          _rule(t.main, 0.6),
          pw.SizedBox(height: 8),
        ],
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // اليمين: اسم المدرس بشكل بارز
            pw.Expanded(
              child: teacher == null
                  ? pw.SizedBox()
                  : pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: t.main, width: 1.2),
                          ),
                        ),
                        child: pw.Text(
                          'الأستاذ / $teacher',
                          style: t.bold.copyWith(fontSize: 12, color: t.main),
                        ),
                      ),
                    ),
            ),
            // الوسط: المدرسة + البسملة
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                children: [
                  if (s.schoolName?.isNotEmpty == true)
                    pw.Text(
                      s.schoolName!,
                      textAlign: pw.TextAlign.center,
                      style: t.bold.copyWith(fontSize: 12),
                    ),
                  if (s.headerText?.isNotEmpty == true)
                    pw.Text(
                      s.headerText!,
                      textAlign: pw.TextAlign.center,
                      style: t.base.copyWith(fontSize: 9),
                    ),
                  if (s.showBazmala)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'بسم الله الرحمن الرحيم',
                        style: t.base.copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            // اليسار: الشعار
            pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: logo == null
                    ? pw.SizedBox()
                    : pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            exam.title,
            textAlign: pw.TextAlign.center,
            style: t.bold.copyWith(fontSize: 16),
          ),
        ),
        if (s.showSubjectGrade) ...[
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              'المادة: ${exam.subject}      الصف: ${exam.grade}',
              style: t.base.copyWith(fontSize: 10.5),
            ),
          ),
        ],
        if (s.showDecorations) ...[
          pw.SizedBox(height: 8),
          _rule(t.main, 0.6),
          pw.SizedBox(height: 2),
          _rule(t.main, 2.4),
        ],
      ],
    );
  }

  /// عصري: بانر ملوّن كامل بنص أبيض وبادجات.
  static pw.Widget _headerModern(
    ExamModel exam,
    ExamPrintSettings s,
    _Theme t,
    String? teacher,
    pw.ImageProvider? logo,
  ) {
    const white = PdfColors.white;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: pw.BoxDecoration(
        color: t.main,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 42,
                  height: 42,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 10),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (s.schoolName?.isNotEmpty == true)
                      pw.Text(
                        s.schoolName!,
                        style: t.bold.copyWith(fontSize: 11, color: white),
                      ),
                    if (s.headerText?.isNotEmpty == true)
                      pw.Text(
                        s.headerText!,
                        style: t.base.copyWith(fontSize: 8.5, color: t.softer),
                      ),
                    if (s.showBazmala)
                      pw.Text(
                        'بسم الله الرحمن الرحيم',
                        style: t.base.copyWith(fontSize: 9, color: t.softer),
                      ),
                  ],
                ),
              ),
              if (teacher != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: white,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    'أ. $teacher',
                    style: t.bold.copyWith(fontSize: 11, color: t.main),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              exam.title,
              textAlign: pw.TextAlign.center,
              style: t.bold.copyWith(fontSize: 19, color: white),
            ),
          ),
          if (s.showSubjectGrade) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _pill(exam.subject, t, filled: true),
                pw.SizedBox(width: 8),
                _pill(exam.grade, t, filled: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// رسمي: بسملة، رأس بثلاثة أعمدة (بيانات | شعار | بيانات)، شريط عنوان مظلل.
  static pw.Widget _headerOfficial(
    ExamModel exam,
    ExamPrintSettings s,
    _Theme t,
    String? teacher,
    pw.ImageProvider? logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (s.showBazmala)
          pw.Center(
            child: pw.Text(
              'بسم الله الرحمن الرحيم',
              style: t.bold.copyWith(fontSize: 11),
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // اليمين
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (s.schoolName?.isNotEmpty == true)
                    pw.Text(
                      s.schoolName!,
                      style: t.bold.copyWith(fontSize: 12, color: t.main),
                    ),
                  if (s.headerText?.isNotEmpty == true)
                    pw.Text(
                      s.headerText!,
                      style: t.base.copyWith(fontSize: 9),
                    ),
                  if (teacher != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        'المدرس: $teacher',
                        style: t.bold.copyWith(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            // الوسط: الشعار
            pw.Container(
              width: 62,
              height: 62,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: t.main, width: 1),
              ),
              padding: const pw.EdgeInsets.all(6),
              child: logo != null
                  ? pw.Image(logo, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        'الشعار',
                        style: t.base.copyWith(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
            ),
            // اليسار
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (s.showSubjectGrade) ...[
                    pw.Text(
                      'المادة: ${exam.subject}',
                      style: t.bold.copyWith(fontSize: 10.5),
                    ),
                    pw.Text(
                      'الصف: ${exam.grade}',
                      style: t.base.copyWith(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 7),
          decoration: pw.BoxDecoration(
            color: t.light,
            border: pw.Border.all(color: t.main, width: 1),
          ),
          child: pw.Center(
            child: pw.Text(
              exam.title,
              textAlign: pw.TextAlign.center,
              style: t.bold.copyWith(fontSize: 15, color: t.main),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Info block ───────────────────────────────────────────────────────────

  static pw.Widget _info(ExamModel exam, ExamPrintSettings s, _Theme t) {
    final time = 'الزمن: ${exam.durationMinutes} دقيقة';
    final marks = 'الدرجة النهائية: ${_marks(exam.totalMarks)}';

    switch (s.template) {
      case ExamTemplate.classic:
        return pw.Column(
          children: [
            if (s.showDurationMarks)
              pw.Row(
                children: [
                  _cell(time, t.bold.copyWith(fontSize: 10), t.main),
                  _cell(marks, t.bold.copyWith(fontSize: 10), t.main),
                ],
              ),
            if (s.showStudentInfo)
              pw.Row(
                children: [
                  _cell('اسم الطالب:', t.base.copyWith(fontSize: 10), t.main,
                      flex: 3, height: 26),
                  _cell('الفصل:', t.base.copyWith(fontSize: 10), t.main,
                      flex: 1, height: 26),
                ],
              ),
          ],
        );

      case ExamTemplate.modern:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (s.showDurationMarks)
              pw.Row(
                children: [
                  pw.Expanded(child: _statBox('الزمن', '${exam.durationMinutes} دقيقة', t)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: _statBox('الدرجة النهائية', _marks(exam.totalMarks), t)),
                ],
              ),
            if (s.showDurationMarks && s.showStudentInfo) pw.SizedBox(height: 10),
            if (s.showStudentInfo)
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: _fillLine('اسم الطالب', t)),
                  pw.SizedBox(width: 14),
                  pw.Expanded(flex: 1, child: _fillLine('الفصل', t)),
                ],
              ),
          ],
        );

      case ExamTemplate.official:
        final lbl = t.bold.copyWith(fontSize: 9.5);
        final val = t.base.copyWith(fontSize: 9.5);
        return pw.Column(
          children: [
            if (s.showStudentInfo)
              pw.Row(
                children: [
                  _cell('اسم الطالب', lbl, t.main, fill: t.light, flex: 2),
                  _cell('', val, t.main, flex: 5),
                  _cell('الفصل', lbl, t.main, fill: t.light, flex: 2),
                  _cell('', val, t.main, flex: 2),
                ],
              ),
            if (s.showDurationMarks)
              pw.Row(
                children: [
                  _cell('الزمن', lbl, t.main, fill: t.light, flex: 2),
                  _cell('${exam.durationMinutes} دقيقة', val, t.main, flex: 2),
                  _cell('الدرجة النهائية', lbl, t.main, fill: t.light, flex: 3),
                  _cell(_marks(exam.totalMarks), val, t.main, flex: 2),
                  _cell('الدرجة المستحقة', lbl, t.main, fill: t.light, flex: 3),
                  _cell('', val, t.main, flex: 2),
                ],
              ),
          ],
        );
    }
  }

  static pw.Widget _instructions(ExamModel exam, ExamPrintSettings s, _Theme t) {
    final text = pw.Text(
      exam.instructions!.trim(),
      style: t.base.copyWith(fontSize: 9.5),
    );
    final title = pw.Text(
      'تعليمات الامتحان',
      style: t.bold.copyWith(fontSize: 10, color: t.main),
    );

    switch (s.template) {
      case ExamTemplate.classic:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(color: t.main, width: 2.5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [title, pw.SizedBox(height: 3), text],
          ),
        );
      case ExamTemplate.modern:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(11),
          decoration: pw.BoxDecoration(
            color: t.light,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [title, pw.SizedBox(height: 3), text],
          ),
        );
      case ExamTemplate.official:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: t.main, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [title, pw.SizedBox(height: 3), text],
          ),
        );
    }
  }

  // ─── Section heading ──────────────────────────────────────────────────────

  static pw.Widget _sectionHeading(String title, ExamPrintSettings s, _Theme t) {
    switch (s.template) {
      case ExamTemplate.classic:
        return pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: t.main, width: 1.4),
              ),
            ),
            child: pw.Text(title, style: t.bold.copyWith(fontSize: 12.5)),
          ),
        );
      case ExamTemplate.modern:
        return pw.Row(
          children: [
            pw.Container(
              width: 5,
              height: 18,
              decoration: pw.BoxDecoration(
                color: t.main,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(title, style: t.bold.copyWith(fontSize: 13, color: t.main)),
          ],
        );
      case ExamTemplate.official:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: t.main,
          ),
          child: pw.Text(
            title,
            style: t.bold.copyWith(fontSize: 11.5, color: PdfColors.white),
          ),
        );
    }
  }

  // ─── Questions ────────────────────────────────────────────────────────────

  static pw.Widget _question(
    QuestionModel q,
    int number,
    ExamPrintSettings s,
    _Theme t,
  ) {
    switch (s.template) {
      case ExamTemplate.classic:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '$number. ${q.text}',
                      style: t.bold.copyWith(fontSize: 11),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    '(${_marks(q.marks)} درجة)',
                    style: t.base.copyWith(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              ..._body(q, t, circle: true),
            ],
          ),
        );

      case ExamTemplate.modern:
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: t.border, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 20,
                    height: 20,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: t.main,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      '$number',
                      style: t.bold.copyWith(
                        fontSize: 9.5,
                        color: PdfColors.white,
                        lineSpacing: 0,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      q.text,
                      style: t.bold.copyWith(fontSize: 10.5),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  _pill('${_marks(q.marks)} درجة', t),
                ],
              ),
              pw.SizedBox(height: 6),
              ..._body(q, t, circle: true),
            ],
          ),
        );

      case ExamTemplate.official:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'س$number',
                    style: t.bold.copyWith(fontSize: 11, color: t.main),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(
                      q.text,
                      style: t.bold.copyWith(fontSize: 10.5),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: t.main, width: 0.8),
                    ),
                    child: pw.Text(
                      '${_marks(q.marks)} د',
                      style: t.bold.copyWith(fontSize: 9, color: t.main),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              ..._body(q, t, circle: false),
              pw.SizedBox(height: 2),
              pw.Container(
                height: 0.4,
                color: t.border,
              ),
            ],
          ),
        );
    }
  }

  /// [circle] = true: دوائر فارغة للاختيار، false: أقواس "( )" للرسمي.
  static List<pw.Widget> _body(
    QuestionModel q,
    _Theme t, {
    required bool circle,
  }) {
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];
    final style = t.base.copyWith(fontSize: 9.5);

    pw.Widget mark() => circle
        ? pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 3),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
            ),
          )
        : pw.Text('(    )', style: style);

    switch (q.type) {
      case QuestionType.multipleChoice:
        return [
          for (var i = 0; i < q.options.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8, bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  mark(),
                  pw.SizedBox(width: 5),
                  pw.Expanded(
                    child: pw.Text(
                      '${letters[i % letters.length]}) ${q.options[i]}',
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
        ];

      case QuestionType.trueFalse:
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 8),
            child: pw.Row(
              children: [
                mark(),
                pw.SizedBox(width: 4),
                pw.Text('صح', style: style),
                pw.SizedBox(width: 26),
                mark(),
                pw.SizedBox(width: 4),
                pw.Text('خطأ', style: style),
              ],
            ),
          ),
        ];

      case QuestionType.complete:
        return _lines(q.answerLines.clamp(1, 10), 15);

      case QuestionType.essay:
        return _lines(q.answerLines.clamp(1, 15), 19);
    }
  }

  static List<pw.Widget> _lines(int count, double height) => List.generate(
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

  // ─── Closing / footer / continuation ──────────────────────────────────────

  static pw.Widget _closing(ExamModel exam, ExamPrintSettings s, _Theme t) {
    final text = 'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق والنجاح';
    switch (s.template) {
      case ExamTemplate.classic:
        return pw.Center(
          child: pw.Text(text, style: t.bold.copyWith(fontSize: 9.5)),
        );
      case ExamTemplate.modern:
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: pw.BoxDecoration(
            color: t.light,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              text,
              style: t.bold.copyWith(fontSize: 9.5, color: t.main),
            ),
          ),
        );
      case ExamTemplate.official:
        return pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'انتهت الأسئلة — مع أطيب التمنيات بالتوفيق',
                style: t.bold.copyWith(fontSize: 9.5, color: t.main),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: t.main, width: 1),
              ),
              child: pw.Text(
                'الدرجة: ........ / ${_marks(exam.totalMarks)}',
                style: t.bold.copyWith(fontSize: 10),
              ),
            ),
          ],
        );
    }
  }

  static pw.Widget _continuationHeader(ExamModel exam, _Theme t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: t.border, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              exam.title,
              maxLines: 1,
              style: t.bold.copyWith(fontSize: 9, color: t.main),
            ),
          ),
          pw.Text(
            '${exam.subject} - ${exam.grade}',
            style: t.base.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx, _Theme t, bool official) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: official ? 4 : 8),
      padding: const pw.EdgeInsets.only(top: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: t.border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ورقتي',
            style: t.bold.copyWith(fontSize: 8, color: t.main),
          ),
          pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            style: t.base.copyWith(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ─── Small building blocks ────────────────────────────────────────────────

  static pw.Widget _rule(PdfColor color, double height) =>
      pw.Container(height: height, color: color);

  static pw.Widget _pill(String text, _Theme t, {bool filled = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: pw.BoxDecoration(
        color: filled ? PdfColors.white : t.light,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        text,
        style: t.bold.copyWith(fontSize: filled ? 10 : 8.5, color: t.main),
      ),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style,
    PdfColor border, {
    int flex = 1,
    PdfColor? fill,
    double height = 22,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        height: height,
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7),
        decoration: pw.BoxDecoration(
          color: fill,
          border: pw.Border.all(color: border, width: 0.7),
        ),
        child: pw.Text(text, style: style),
      ),
    );
  }

  static pw.Widget _statBox(String label, String value, _Theme t) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: t.light,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: t.base.copyWith(fontSize: 9.5)),
          pw.Text(
            value,
            style: t.bold.copyWith(fontSize: 11, color: t.main),
          ),
        ],
      ),
    );
  }

  static pw.Widget _fillLine(String label, _Theme t) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('$label:', style: t.bold.copyWith(fontSize: 9.5)),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Container(
            height: 16,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Color helpers ────────────────────────────────────────────────────────

  /// ملحوظة: في Flutter الحديث Color.r/g/b بين 0 و 1 (مش 0..255)،
  /// فالقسمة على 255 كانت بتطلّع كل الألوان سودا. بنقرأ القيم من ARGB.
  static PdfColor _toPdfColor(Color color) {
    final argb = color.toARGB32();
    return PdfColor(
      ((argb >> 16) & 0xFF) / 255.0,
      ((argb >> 8) & 0xFF) / 255.0,
      (argb & 0xFF) / 255.0,
    );
  }

  static PdfColor _lighten(PdfColor c, double amount) => PdfColor(
        c.red + (1.0 - c.red) * amount,
        c.green + (1.0 - c.green) * amount,
        c.blue + (1.0 - c.blue) * amount,
      );
}

class _Theme {
  final pw.TextStyle base;
  final pw.TextStyle bold;
  final PdfColor main;
  final PdfColor light;
  final PdfColor softer;
  final PdfColor border;

  const _Theme({
    required this.base,
    required this.bold,
    required this.main,
    required this.light,
    required this.softer,
    required this.border,
  });
}
