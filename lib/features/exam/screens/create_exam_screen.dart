import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam/exam_cubit.dart';
import '../repos/exam_repository.dart';
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
  final _subjectCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _instructions = TextEditingController();
  int _duration = 60;

  List<String> _subjectSuggestions = [];
  List<String> _gradeSuggestions = [];
  bool _suggestionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final repo = ExamRepository();
    final subjects = await repo.getUsedSubjects();
    final grades = await repo.getUsedGrades();
    if (!mounted) return;
    setState(() {
      _subjectSuggestions = subjects;
      _gradeSuggestions = grades;
      _suggestionsLoaded = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _teacher.dispose();
    _subjectCtrl.dispose();
    _gradeCtrl.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: waraqtyBackground,
        appBar: AppBar(
          backgroundColor: waraqtyBackground,
          elevation: 0,
          title: const Text(
            'إنشاء امتحان جديد',
            style: TextStyle(fontWeight: FontWeight.w700),
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
              const _StepHeader(
                step: 1,
                title: 'بيانات الامتحان',
                subtitle: 'الخطوة الأولى من ٣',
              ),
              const SizedBox(height: 18),

              // ── معاينة رأس الورقة ─────────────────────────────────────
              Container(
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
                      style: TextStyle(
                        color: waraqtyPurple,
                        fontWeight: FontWeight.bold,
                      ),
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
                          const SizedBox(height: 6),
                          Text(
                            '${_subjectCtrl.text.isEmpty ? 'المادة' : _subjectCtrl.text} • ${_gradeCtrl.text.isEmpty ? 'الصف الدراسي' : _gradeCtrl.text}',
                            textAlign: TextAlign.center,
                          ),
                          const Divider(),
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
              ),
              const SizedBox(height: 18),

              // ── الحقول ────────────────────────────────────────────────
              const _FieldLabel('عنوان أو اسم الامتحان'),
              TextFormField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب اسم الامتحان' : null,
                decoration: _input('مثال: امتحان شهر نوفمبر - رياضيات'),
              ),
              const SizedBox(height: 14),

              const _FieldLabel('المادة الدراسية'),
              _AutocompleteField(
                controller: _subjectCtrl,
                hint: 'اكتب أو اختر المادة الدراسية',
                suggestions: _suggestionsLoaded ? _subjectSuggestions : [],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب اسم المادة' : null,
              ),
              const SizedBox(height: 14),

              const _FieldLabel('الصف الدراسي'),
              _AutocompleteField(
                controller: _gradeCtrl,
                hint: 'اكتب أو اختر الصف / المرحلة الدراسية',
                suggestions: _suggestionsLoaded ? _gradeSuggestions : [],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب الصف الدراسي' : null,
              ),
              const SizedBox(height: 14),

              const _FieldLabel('اسم المدرس (اختياري)'),
              TextFormField(
                controller: _teacher,
                decoration: _input('اكتب اسم المدرس'),
              ),
              const SizedBox(height: 14),

              const _FieldLabel('زمن الامتحان'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 45, 60, 90, 120]
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

              const _FieldLabel('تعليمات الامتحان (اختياري)'),
              TextFormField(
                controller: _instructions,
                maxLines: 3,
                decoration: _input('مثال: أجب عن جميع الأسئلة'),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: waraqtyPurple,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  context.read<ExamCubit>().startDraft(
                    title: _title.text,
                    subject: _subjectCtrl.text.trim(),
                    grade: _gradeCtrl.text.trim(),
                    teacherName: _teacher.text,
                    durationMinutes: _duration,
                    instructions: _instructions.text,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuestionsBankScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('التالي: إضافة الأسئلة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Autocomplete Field ─────────────────────────────────────────────────────

class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> suggestions;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _AutocompleteField({
    required this.controller,
    required this.hint,
    required this.suggestions,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return suggestions.take(8);
        return suggestions.where(
          (s) => s.toLowerCase().contains(query),
        );
      },
      onSelected: (value) {
        controller.text = value;
        onChanged?.call(value);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        // Sync controllers on first build.
        if (fieldController.text.isEmpty && controller.text.isNotEmpty) {
          fieldController.text = controller.text;
        }
        fieldController.addListener(() {
          if (controller.text != fieldController.text) {
            controller.text = fieldController.text;
            onChanged?.call(fieldController.text);
          }
        });
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          validator: validator == null
              ? null
              : (_) => validator!(controller.text),
          decoration: _input(hint).copyWith(
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8A7BAD),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(13),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: waraqtyPurple,
        child: Text('$step', style: const TextStyle(color: Colors.white)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

InputDecoration _input(String hint) => InputDecoration(
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
    borderSide: const BorderSide(color: waraqtyPurple, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Colors.redAccent),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
  ),
);
