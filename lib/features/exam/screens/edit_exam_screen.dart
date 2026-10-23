import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam_cubit.dart';
import '../models/exam_model.dart';
import 'edit_questions_screen.dart';

const _purple = Color(0xFF431599);
const _background = Color(0xFFFAF9FF);

class EditExamScreen extends StatefulWidget {
  /// الامتحان المراد تعديله – يُستخدم لتعبئة الحقول مسبقاً.
  final ExamModel exam;

  const EditExamScreen({super.key, required this.exam});

  @override
  State<EditExamScreen> createState() => _EditExamScreenState();
}

class _EditExamScreenState extends State<EditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _teacher;
  late final TextEditingController _instructions;
  String? _subject;
  String? _grade;
  late int _duration;

  final _subjects = const [
    'اللغة العربية',
    'اللغة الإنجليزية',
    'الرياضيات',
    'العلوم',
    'الدراسات الاجتماعية',
    'اللغة الفرنسية',
  ];
  final _grades = const [
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  final _durations = const [30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _title = TextEditingController(text: e.title);
    _teacher = TextEditingController(text: e.teacherName ?? '');
    _instructions = TextEditingController(text: e.instructions ?? '');
    _subject = _subjects.contains(e.subject) ? e.subject : null;
    _grade = _grades.contains(e.grade) ? e.grade : null;
    _duration = _durations.contains(e.durationMinutes) ? e.durationMinutes : 60;
  }

  @override
  void dispose() {
    _title.dispose();
    _teacher.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'تعديل بيانات الامتحان',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // ── معاينة مصغرة ─────────────────────────────────────────
              _buildMiniPreview(context),
              const SizedBox(height: 20),

              // ── الحقول ───────────────────────────────────────────────
              _label('عنوان أو اسم الامتحان'),
              _field(
                controller: _title,
                hint: 'مثال: امتحان شهر نوفمبر – رياضيات',
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب اسم الامتحان' : null,
              ),
              const SizedBox(height: 14),

              _label('المادة الدراسية'),
              DropdownButtonFormField<String>(
                value: _subject,
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v),
                validator: (v) => v == null ? 'اختر المادة' : null,
                decoration: _inputDeco('اختر المادة'),
              ),
              const SizedBox(height: 14),

              _label('الصف الدراسي'),
              DropdownButtonFormField<String>(
                value: _grade,
                items: _grades
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'اختر الصف الدراسي' : null,
                decoration: _inputDeco('اختر الصف'),
              ),
              const SizedBox(height: 14),

              _label('اسم المدرس (اختياري)'),
              _field(
                controller: _teacher,
                hint: 'اكتب اسم المدرس',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              _label('زمن الامتحان'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations
                    .map(
                      (m) => ChoiceChip(
                        label: Text('$m دقيقة'),
                        selected: _duration == m,
                        selectedColor: const Color(0xFFE9DDFF),
                        onSelected: (_) => setState(() => _duration = m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),

              _label('تعليمات الامتحان (اختياري)'),
              _field(
                controller: _instructions,
                hint: 'مثال: أجب عن جميع الأسئلة',
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onNext,
                icon: const Icon(Icons.arrow_back),
                label: const Text('التالي: تعديل الأسئلة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Widget _buildMiniPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معاينة رأس ورقة الامتحان',
            style: TextStyle(color: _purple, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // اسم المدرس صغير في اليمين
                if (_teacher.text.trim().isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _teacher.text.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF514663),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'بسم الله الرحمن الرحيم',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _title.text.isEmpty
                      ? 'عنوان الامتحان سيظهر هنا'
                      : _title.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_subject ?? 'المادة'} • ${_grade ?? 'الصف الدراسي'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الزمن: $_duration دقيقة'),
                    Text(
                      'الدرجة: ${context.watch<ExamCubit>().draft?.totalMarks.toStringAsFixed(0) ?? '—'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ExamCubit>().editDraftDetails(
      title: _title.text,
      subject: _subject!,
      grade: _grade!,
      teacherName: _teacher.text,
      durationMinutes: _duration,
      instructions: _instructions.text,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditQuestionsScreen()),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    onChanged: onChanged,
    validator: validator,
    maxLines: maxLines,
    decoration: _inputDeco(hint),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFE4E0ED)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: _purple, width: 1.5),
    ),
  );
}
