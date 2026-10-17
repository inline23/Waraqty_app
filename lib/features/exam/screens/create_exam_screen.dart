import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam_cubit.dart';
import 'questions_bank_screen.dart';

const waraqtyPurple = Color(0xFF431599);
const waraqtyBackground = Color(0xFFFAF9FF);

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});
  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _teacher = TextEditingController();
  final _instructions = TextEditingController();
  String? _subject;
  String? _grade;
  int _duration = 60;

  final _subjects = const ['اللغة العربية', 'اللغة الإنجليزية', 'الرياضيات', 'العلوم', 'الدراسات الاجتماعية', 'اللغة الفرنسية'];
  final _grades = const ['الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي', 'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي', 'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي'];

  @override
  void dispose() {
    _title.dispose(); _teacher.dispose(); _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: waraqtyBackground,
        appBar: AppBar(
          backgroundColor: waraqtyBackground, elevation: 0,
          title: const Text('إنشاء امتحان جديد', style: TextStyle(fontWeight: FontWeight.w700)),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const _StepHeader(step: 1, title: 'بيانات الامتحان', subtitle: 'الخطوة الأولى من ٣'),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('معاينة رأس ورقة الامتحان', style: TextStyle(color: waraqtyPurple, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Text('بسم الله الرحمن الرحيم', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_title.text.isEmpty ? 'عنوان الامتحان سيظهر هنا' : _title.text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 6),
                      Text('${_subject ?? 'المادة'} • ${_grade ?? 'الصف الدراسي'}', textAlign: TextAlign.center),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('الزمن: $_duration دقيقة'),
                        Text('الدرجة: ${context.watch<ExamCubit>().draft?.totalMarks.toStringAsFixed(0) ?? '—'}'),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              _FieldLabel('عنوان أو اسم الامتحان'),
              TextFormField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم الامتحان' : null,
                decoration: _input('مثال: امتحان شهر نوفمبر - رياضيات'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('المادة الدراسية'),
              DropdownButtonFormField<String>(
                value: _subject, items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _subject = v),
                validator: (v) => v == null ? 'اختر المادة' : null,
                decoration: _input('اختر المادة'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('الصف الدراسي'),
              DropdownButtonFormField<String>(
                value: _grade, items: _grades.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'اختر الصف الدراسي' : null,
                decoration: _input('اختر الصف'),
              ),
              const SizedBox(height: 14),
              _FieldLabel('اسم المدرس (اختياري)'),
              TextFormField(controller: _teacher, decoration: _input('اكتب اسم المدرس')),
              const SizedBox(height: 14),
              _FieldLabel('زمن الامتحان'),
              Wrap(spacing: 8, runSpacing: 8, children: [30, 45, 60, 90, 120].map((m) =>
                ChoiceChip(label: Text('$m دقيقة'), selected: _duration == m, selectedColor: const Color(0xFFE9DDFF),
                  onSelected: (_) => setState(() => _duration = m))).toList()),
              const SizedBox(height: 14),
              _FieldLabel('تعليمات الامتحان (اختياري)'),
              TextFormField(controller: _instructions, maxLines: 3, decoration: _input('مثال: أجب عن جميع الأسئلة')),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: waraqtyPurple, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  context.read<ExamCubit>().startDraft(
                    title: _title.text, subject: _subject!, grade: _grade!,
                    teacherName: _teacher.text, durationMinutes: _duration,
                    instructions: _instructions.text,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionsBankScreen()));
                },
                icon: const Icon(Icons.arrow_back), label: const Text('التالي: إضافة الأسئلة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step; final String title; final String subtitle;
  const _StepHeader({required this.step, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    CircleAvatar(backgroundColor: waraqtyPurple, child: Text('$step', style: const TextStyle(color: Colors.white))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(subtitle, style: const TextStyle(color: Colors.black54)),
    ])),
  ]);
}
class _FieldLabel extends StatelessWidget {
  final String text; const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)));
}
InputDecoration _input(String hint) => InputDecoration(
  hintText: hint, filled: true, fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE4E0ED))),
);
