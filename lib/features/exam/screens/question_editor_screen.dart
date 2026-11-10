import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/exam/cubit/exam/exam_cubit.dart';
import 'package:waraqty_app/features/exam/cubit/questions/question_bank_cubit.dart';

import '../models/bank_question_model.dart';
import '../models/question_model.dart';
import '../models/question_type.dart';

class QuestionEditorScreen extends StatefulWidget {
  final QuestionType type;
  final QuestionModel? question;

  /// لو متحدد، المحرر بيعدّل سؤال في بنك الأسئلة (مش في امتحان).
  final BankQuestion? bankItem;
  const QuestionEditorScreen({
    super.key,
    required this.type,
    this.question,
    this.bankItem,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final TextEditingController _answer;
  late final List<TextEditingController> _options;
  late final TextEditingController _customMarks;
  double _marks = 1;
  int _answerLines = 3;
  bool get _isEditing => widget.question != null;
  bool get _isBankMode => widget.bankItem != null;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _text = TextEditingController(text: q?.text ?? '');
    _answer = TextEditingController(text: q?.correctAnswer ?? '');
    _options = (q?.options.isNotEmpty == true ? q!.options : (widget.type == QuestionType.multipleChoice ? ['', '', '', ''] : <String>[]))
      .map((s) => TextEditingController(text: s)).toList();
    _customMarks = TextEditingController();
    _marks = q?.marks ?? 1;
    _answerLines = q?.answerLines ?? 3;
  }

  @override
  void dispose() {
    _text.dispose(); _answer.dispose(); _customMarks.dispose();
    for (final option in _options) { option.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = _isBankMode ? null : context.read<ExamCubit>().draft;
    final subject = widget.bankItem?.subject ?? exam?.subject ?? '';
    final grade = widget.bankItem?.grade ?? exam?.grade ?? '';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FF),
        appBar: AppBar(backgroundColor: const Color(0xFFFAF9FF), elevation: 0, title: Text(_isBankMode ? 'تعديل سؤال في البنك' : (_isEditing ? 'تعديل السؤال' : 'محرر السؤال'))),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.format_list_bulleted, color: Color(0xFF431599)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.type.arabicName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('$grade • $subject', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ])),
                ])),
              const SizedBox(height: 18),
              const Text('صيغة السؤال *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _text, maxLines: 4, minLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'اكتب نص السؤال' : null,
                decoration: _decoration('اكتب نص السؤال هنا بدقة...'),
              ),
              const SizedBox(height: 18),
              if (widget.type == QuestionType.multipleChoice) ...[
                Row(children: [
                  const Expanded(child: Text('بدائل الإجابة', style: TextStyle(fontWeight: FontWeight.bold))),
                  TextButton.icon(onPressed: _options.length >= 8 ? null : () => setState(() => _options.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text('إضافة بديل')),
                ]),
                ...List.generate(_options.length, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: index == 0 ? const Color(0xFF5B35B1) : const Color(0xFFE6E0F3),
                      child: Text(_arabicLetter(index), style: TextStyle(color: index == 0 ? Colors.white : const Color(0xFF431599)))),
                    const SizedBox(width: 9),
                    Expanded(child: TextFormField(controller: _options[index], validator: (v) => v == null || v.trim().isEmpty ? 'أكمل البديل أو احذفه' : null, decoration: _decoration('نص البديل'))),
                    IconButton(onPressed: _options.length <= 2 ? null : () => setState(() { _options.removeAt(index).dispose(); }), icon: const Icon(Icons.backspace_outlined, size: 20)),
                  ]),
                )),
              ],
              if (widget.type == QuestionType.complete || widget.type == QuestionType.trueFalse) ...[
                const Text('الإجابة النموذجية (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (widget.type == QuestionType.trueFalse)
                  DropdownButtonFormField<String>(
                    value: _answer.text.isEmpty ? null : _answer.text,
                    items: const [DropdownMenuItem(value: 'صح', child: Text('صح')), DropdownMenuItem(value: 'خطأ', child: Text('خطأ'))],
                    onChanged: (v) => _answer.text = v ?? '',
                    decoration: _decoration('اختر الإجابة النموذجية'),
                  )
                else
                  TextFormField(controller: _answer, decoration: _decoration('الإجابة النموذجية إن لزم')),
              ],
              if (widget.type == QuestionType.essay) ...[
                const Text('عدد أسطر الإجابة', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _answerLines,
                  items: [2, 3, 4, 5, 6, 8, 10].map((n) => DropdownMenuItem(value: n, child: Text('$n أسطر'))).toList(),
                  onChanged: (v) => setState(() => _answerLines = v ?? 3),
                  decoration: _decoration('حدد مساحة الإجابة'),
                ),
              ],
              const SizedBox(height: 18),
              const Text('درجة السؤال', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [1.0, 2.0, 5.0, 10.0].map((score) => ChoiceChip(
                label: Text('${score.toInt()} درجة'), selected: _marks == score,
                selectedColor: const Color(0xFFE9DDFF),
                onSelected: (_) => setState(() { _marks = score; _customMarks.clear(); }),
              )).toList()),
              const SizedBox(height: 10),
              TextFormField(
                controller: _customMarks, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('أو أدخل درجة مخصصة'),
                onChanged: (value) { final parsed = double.tryParse(value); if (parsed != null && parsed > 0) setState(() => _marks = parsed); },
              ),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF431599)),
                  SizedBox(width: 10),
                  Expanded(child: Text('الإجابة النموذجية اختيارية؛ يمكنك إعداد ورقة الطالب دون إظهار الإجابات.')),
                ])),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isBankMode && exam != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF431599),
                      side: const BorderSide(color: Color(0xFFBBA7E4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _saveToBank(exam.subject, exam.grade),
                    icon: const Icon(Icons.inventory_2_outlined, size: 19),
                    label: const Text('إضافة السؤال إلى بنك الأسئلة'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF431599), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(_isBankMode ? 'حفظ التعديلات في البنك' : (_isEditing ? 'حفظ التعديلات' : 'حفظ السؤال في الامتحان')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  QuestionModel? _buildQuestion() {
    if (!_formKey.currentState!.validate()) return null;
    final now = DateTime.now();
    return QuestionModel(
      id: widget.question?.id ?? 'question_${now.microsecondsSinceEpoch}',
      type: widget.type,
      text: _text.text.trim(),
      marks: _marks,
      options: widget.type == QuestionType.multipleChoice ? _options.map((e) => e.text.trim()).toList() : const [],
      correctAnswer: _answer.text.trim().isEmpty ? null : _answer.text.trim(),
      answerLines: _answerLines,
      createdAt: widget.question?.createdAt ?? now,
    );
  }

  void _submit() {
    final question = _buildQuestion();
    if (question == null) return;
    if (_isBankMode) {
      context.read<QuestionBankCubit>().updateQuestion(widget.bankItem!.id, question);
    } else {
      final cubit = context.read<ExamCubit>();
      if (_isEditing) { cubit.updateQuestion(question); } else { cubit.addQuestion(question); }
    }
    Navigator.pop(context);
  }

  /// يحفظ السؤال الحالي في البنك (نسخة مستقلة) ويفضل المحرر مفتوح.
  Future<void> _saveToBank(String subject, String grade) async {
    final question = _buildQuestion();
    if (question == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final bank = context.read<QuestionBankCubit>();
    try {
      final isNew = await bank.saveQuestion(question, subject: subject, grade: grade);
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(isNew ? 'تمت إضافة السؤال إلى بنك الأسئلة' : 'السؤال موجود بالفعل في بنك الأسئلة'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('تعذر الحفظ في بنك الأسئلة: $e'),
      ));
    }
  }

  String _arabicLetter(int index) {
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];
    return letters[index % letters.length];
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E0ED))),
  );
}
