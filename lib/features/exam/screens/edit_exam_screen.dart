import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam_cubit.dart';
import '../models/exam_model.dart';
import '../repos/exam_repository.dart';
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
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _instructions;
  late int _duration;

  final _durations = const [30, 45, 60, 90, 120];

  List<String> _subjectSuggestions = [];
  List<String> _gradeSuggestions = [];
  bool _suggestionsLoaded = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _title = TextEditingController(text: e.title);
    _teacher = TextEditingController(text: e.teacherName ?? '');
    _subjectCtrl = TextEditingController(text: e.subject);
    _gradeCtrl = TextEditingController(text: e.grade);
    _instructions = TextEditingController(text: e.instructions ?? '');
    _duration = _durations.contains(e.durationMinutes) ? e.durationMinutes : 60;
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
              _AutocompleteField(
                controller: _subjectCtrl,
                hint: 'اكتب أو اختر المادة الدراسية',
                suggestions: _suggestionsLoaded ? _subjectSuggestions : [],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب اسم المادة' : null,
              ),
              const SizedBox(height: 14),

              _label('الصف الدراسي'),
              _AutocompleteField(
                controller: _gradeCtrl,
                hint: 'اكتب أو اختر الصف / المرحلة الدراسية',
                suggestions: _suggestionsLoaded ? _gradeSuggestions : [],
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'اكتب الصف الدراسي' : null,
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
                  _title.text.isEmpty ? 'عنوان الامتحان سيظهر هنا' : _title.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_subjectCtrl.text.isEmpty ? 'المادة' : _subjectCtrl.text} • ${_gradeCtrl.text.isEmpty ? 'الصف الدراسي' : _gradeCtrl.text}',
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
      subject: _subjectCtrl.text.trim(),
      grade: _gradeCtrl.text.trim(),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
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
      initialValue: TextEditingValue(text: controller.text),
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
          decoration: InputDecoration(
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
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
