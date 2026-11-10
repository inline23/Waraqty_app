import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/exam/cubit/exam/exam_cubit.dart';
import 'package:waraqty_app/features/exam/cubit/questions/question_bank_cubit.dart';

import '../models/bank_question_model.dart';
import '../models/question_type.dart';
import 'question_editor_screen.dart';

String _formatMarks(double marks) => marks == marks.roundToDouble()
    ? marks.toInt().toString()
    : marks.toString();

/// يفتح بنك الأسئلة للاختيار ويضيف الأسئلة المختارة للمسودة الحالية كنسخ مستقلة.
/// المسودة نفسها لا تتغير لحد ما المستخدم يأكد الاختيار.
Future<void> pickQuestionsFromBank(BuildContext context) async {
  final examCubit = context.read<ExamCubit>();
  final draft = examCubit.draft;
  if (draft == null) return;
  final messenger = ScaffoldMessenger.of(context);

  final picked = await Navigator.push<List<BankQuestion>>(
    context,
    MaterialPageRoute(
      builder: (_) => SavedQuestionsScreen(
        selectionMode: true,
        excludedSignatures: draft.questions.map((q) => q.signature).toSet(),
      ),
    ),
  );
  if (picked == null || picked.isEmpty) return;

  final added = examCubit.addBankQuestions(picked);
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        added == 0
            ? 'الأسئلة المختارة موجودة بالفعل في الامتحان'
            : 'تمت إضافة $added سؤال من بنك الأسئلة',
      ),
    ),
  );
}

/// بنك الأسئلة: كل الأسئلة اللي استخدمها المدرس في امتحاناته المحفوظة.
///
/// - [selectionMode] = false: شاشة تصفح (تبويب "بنك الأسئلة").
/// - [selectionMode] = true: اختيار أسئلة لإضافتها لامتحان، وترجع
///   List<BankQuestion> عبر Navigator.pop.
class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen({
    super.key,
    this.selectionMode = false,
    this.excludedSignatures = const {},
  });

  final bool selectionMode;

  /// بصمات أسئلة موجودة بالفعل في الامتحان (تظهر معطّلة).
  final Set<String> excludedSignatures;

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  static const Color purple = Color(0xFF431599);
  static const Color background = Color(0xFFFAF9FF);
  static const Color lavender = Color(0xFFF1ECFA);
  static const Color border = Color(0xFFECE6F5);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  QuestionType? _type;
  String? _subject;
  String? _grade;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QuestionBankCubit>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _usageCounts() {
    final usage = <String, int>{};
    for (final exam in context.read<ExamCubit>().exams) {
      for (final signature in exam.questions.map((q) => q.signature).toSet()) {
        usage[signature] = (usage[signature] ?? 0) + 1;
      }
    }
    return usage;
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  /// تعديل سؤال في البنك فقط؛ الامتحانات المحفوظة بتفضل زي ما هي.
  void _edit(BankQuestion item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          type: item.question.type,
          question: item.question,
          bankItem: item,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BankQuestion item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف السؤال من البنك؟'),
          content: const Text(
            'سيُحذف السؤال من بنك الأسئلة فقط، ولن يتأثر به أي امتحان محفوظ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    _selected.remove(item.id);
    await context.read<QuestionBankCubit>().delete(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: widget.selectionMode,
          title: Text(
            widget.selectionMode ? 'اختر من بنك الأسئلة' : 'بنك الأسئلة',
            style: TextStyle(
              color: widget.selectionMode ? null : purple,
              fontSize: widget.selectionMode ? 20 : 23,
              fontWeight: widget.selectionMode
                  ? FontWeight.w700
                  : FontWeight.w800,
            ),
          ),
        ),
        body: BlocBuilder<QuestionBankCubit, QuestionBankState>(
          builder: (context, state) {
            if (state is QuestionBankInitial || state is QuestionBankLoading) {
              return const Center(
                child: CircularProgressIndicator(color: purple),
              );
            }
            if (state is QuestionBankFailure) return _buildError(state.message);

            final items = context.read<QuestionBankCubit>().items;
            return _buildContent(items);
          },
        ),
        bottomNavigationBar: widget.selectionMode ? _buildSelectionBar() : null,
      ),
    );
  }

  Widget _buildContent(List<BankQuestion> items) {
    final usage = _usageCounts();

    final subjects =
        items.map((i) => i.subject).where((s) => s.isNotEmpty).toSet().toList()
          ..sort();
    final subjectValue = subjects.contains(_subject) ? _subject : null;
    final grades =
        items.map((i) => i.grade).where((s) => s.isNotEmpty).toSet().toList()
          ..sort();
    final gradeValue = grades.contains(_grade) ? _grade : null;

    final q = _query.trim().toLowerCase();
    final filtered = items.where((item) {
      if (_type != null && item.question.type != _type) return false;
      if (subjectValue != null && item.subject != subjectValue) return false;
      if (gradeValue != null && item.grade != gradeValue) return false;
      if (q.isEmpty) return true;
      return item.question.text.toLowerCase().contains(q) ||
          item.question.options.any((o) => o.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      color: purple,
      onRefresh: () => context.read<QuestionBankCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          widget.selectionMode ? 16 : 28,
        ),
        children: [
          if (!widget.selectionMode) ...[
            _buildIntro(items.length),
            const SizedBox(height: 20),
          ],
          if (items.isEmpty)
            _buildEmpty()
          else ...[
            _buildSearch(),
            const SizedBox(height: 12),
            _buildTypeFilters(),
            if (subjects.length > 1 || grades.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (subjects.length > 1)
                    Expanded(
                      child: _buildDropdown(
                        'كل المواد',
                        subjects,
                        subjectValue,
                        (v) => setState(() => _subject = v),
                      ),
                    ),
                  if (subjects.length > 1 && grades.length > 1)
                    const SizedBox(width: 10),
                  if (grades.length > 1)
                    Expanded(
                      child: _buildDropdown(
                        'كل الصفوف',
                        grades,
                        gradeValue,
                        (v) => setState(() => _grade = v),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${filtered.length} سؤال',
              style: const TextStyle(
                color: purple,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              _buildNoResults()
            else
              ...filtered.map(
                (item) => _buildCard(item, usage[item.signature] ?? 0),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntro(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF431599), Color(0xFF7047C6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'كل أسئلتك في مكان واحد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عندك $count سؤال محفوظ. أي سؤال تستخدمه في امتحان '
                  'بيتحفظ هنا تلقائيًا، وتقدر تعيد استخدامه في أي امتحان تاني.',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.inventory_2_outlined, size: 46, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'ابحث في نص السؤال أو البدائل',
        prefixIcon: const Icon(Icons.search_rounded, color: purple),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5DDF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5DDF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('الكل'),
          selected: _type == null,
          selectedColor: const Color(0xFFE9DDFF),
          onSelected: (_) => setState(() => _type = null),
        ),
        ...QuestionType.values.map(
          (type) => ChoiceChip(
            label: Text(type.arabicName),
            selected: _type == type,
            selectedColor: const Color(0xFFE9DDFF),
            onSelected: (_) =>
                setState(() => _type = _type == type ? null : type),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String allLabel,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5DDF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5DDF3)),
        ),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
        ...options.map(
          (s) => DropdownMenuItem<String?>(
            value: s,
            child: Text(s, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCard(BankQuestion item, int usageCount) {
    final question = item.question;
    final already = widget.excludedSignatures.contains(item.signature);
    final selected = _selected.contains(item.id);
    const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];

    return Opacity(
      opacity: already ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? purple : border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.selectionMode && !already
              ? () => _toggle(item.id)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selectionMode) ...[
                  Checkbox(
                    value: already ? true : selected,
                    activeColor: purple,
                    onChanged: already ? null : (_) => _toggle(item.id),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _chip(question.type.arabicName, filled: true),
                          if (item.subject.isNotEmpty || item.grade.isNotEmpty)
                            Text(
                              [
                                item.subject,
                                item.grade,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF292333),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                        ),
                      ),
                      if (question.options.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (
                          var i = 0;
                          i < question.options.length && i < 4;
                          i++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${letters[i % letters.length]}) ${question.options[i]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        if (question.options.length > 4)
                          Text(
                            '+ ${question.options.length - 4} بدائل أخرى',
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 11,
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip('${_formatMarks(question.marks)} درجة'),
                          _chip(
                            usageCount == 0
                                ? 'غير مستخدم حاليًا'
                                : 'استُخدم في $usageCount امتحان',
                          ),
                          if (already) _chip('موجود في هذا الامتحان'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!widget.selectionMode)
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'تعديل السؤال',
                        onPressed: () => _edit(item),
                        icon: const Icon(Icons.edit_outlined, color: purple),
                      ),
                      IconButton(
                        tooltip: 'حذف من البنك',
                        onPressed: () => _confirmDelete(item),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? lavender : const Color(0xFFF8F5FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? purple : const Color(0xFF514663),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: lavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: purple,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'بنك الأسئلة فاضي لسه',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'احفظ أي امتحان وأسئلته هتتضاف هنا تلقائيًا،\nوتقدر تستخدمها تاني في امتحانات جديدة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Padding(
      padding: EdgeInsets.only(top: 30),
      child: Center(
        child: Text(
          'مفيش أسئلة مطابقة للبحث أو الفلتر.',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 45,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.read<QuestionBankCubit>().load(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _selected.isEmpty
                ? null
                : () {
                    final picked = context
                        .read<QuestionBankCubit>()
                        .items
                        .where((i) => _selected.contains(i.id))
                        .toList();
                    Navigator.pop(context, picked);
                  },
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: Text(
              _selected.isEmpty
                  ? 'اختر أسئلة لإضافتها'
                  : 'إضافة ${_selected.length} سؤال للامتحان',
            ),
          ),
        ),
      ),
    );
  }
}
