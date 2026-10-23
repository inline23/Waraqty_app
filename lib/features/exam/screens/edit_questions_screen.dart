import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam_cubit.dart';
import '../models/question_model.dart';
import 'question_editor_screen.dart';
import 'question_type_screen.dart';
import 'exam_preview_screen.dart';

const _purple = Color(0xFF431599);
const _background = Color(0xFFFAF9FF);
const _lavender = Color(0xFFE9DDFF);

class EditQuestionsScreen extends StatelessWidget {
  const EditQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<ExamCubit, ExamState>(
        listener: (context, state) {
          if (state is ExamOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _purple,
              ),
            );
            // العودة لشاشة امتحاناتي
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (state is ExamFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<ExamCubit>();
          final exam = cubit.draft;

          if (exam == null) {
            return const Scaffold(
              body: Center(child: Text('لا يوجد امتحان للتعديل.')),
            );
          }

          final isSaving = state is ExamSaving;

          return Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'تعديل الأسئلة',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                TextButton.icon(
                  onPressed: exam.questions.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamPreviewScreen(exam: exam),
                            ),
                          ),
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text('معاينة'),
                  style: TextButton.styleFrom(foregroundColor: _purple),
                ),
              ],
            ),
            body: Column(
              children: [
                // ── بطاقة الملخص ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _SummaryCard(exam: exam),
                ),
                const SizedBox(height: 12),

                // ── قائمة الأسئلة بـ Drag & Drop ─────────────────────
                Expanded(
                  child: exam.questions.isEmpty
                      ? _buildEmpty(context)
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: exam.questions.length,
                          onReorder: cubit.reorderQuestion,
                          proxyDecorator: (child, index, animation) =>
                              Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(14),
                                shadowColor: _purple.withOpacity(0.2),
                                child: child,
                              ),
                          itemBuilder: (context, index) {
                            final q = exam.questions[index];
                            return _QuestionEditTile(
                              key: ValueKey(q.id),
                              index: index,
                              question: q,
                              onEdit: () => _editQuestion(context, q),
                              onDelete: () => _confirmDelete(context, q),
                            );
                          },
                        ),
                ),

                // ── الأزرار السفلية ───────────────────────────────────
                _buildBottomBar(context, cubit, isSaving, exam.questions.isEmpty),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFF1ECFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 48,
                color: _purple,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد أسئلة بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف أسئلة للامتحان أو احذف أسئلة قديمة وأضف بديلاً عنها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ExamCubit cubit,
    bool isSaving,
    bool noQuestions,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر إضافة سؤال
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuestionTypeScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة سؤال'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: Color(0xFFBBA7E4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // زر حفظ التعديلات
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: (noQuestions || isSaving)
                    ? null
                    : () => cubit.saveDraft(),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editQuestion(BuildContext context, QuestionModel question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorScreen(
          type: question.type,
          question: question,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, QuestionModel question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف السؤال؟'),
          content: Text(
            'هل تريد حذف السؤال:\n"${question.text}"؟',
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

    if (confirmed == true && context.mounted) {
      context.read<ExamCubit>().deleteQuestion(question.id);
    }
  }
}

// ── بطاقة الملخص ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final dynamic exam;
  const _SummaryCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: _lavender,
            child: Icon(Icons.analytics_outlined, color: _purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exam.questions.length} سؤال',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  exam.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _lavender,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'المجموع: ${exam.totalMarks.toStringAsFixed(exam.totalMarks % 1 == 0 ? 0 : 1)} درجة',
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── تايل السؤال القابل للتعديل ────────────────────────────────────────────────

class _QuestionEditTile extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionEditTile({
    super.key,
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE6F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // مقبض السحب (تلميح مرئي)
            const Icon(Icons.drag_handle_rounded,
                color: Color(0xFFBDB5C9), size: 20),
            const SizedBox(height: 2),
            CircleAvatar(
              radius: 13,
              backgroundColor: _lavender,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _purple,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          question.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _typeChip(question.type.arabicName),
              const SizedBox(width: 6),
              _typeChip('${_formatMarks(question.marks)} درجة',
                  isMarks: true),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر تعديل
            IconButton(
              tooltip: 'تعديل السؤال',
              icon: const Icon(Icons.edit_outlined,
                  color: _purple, size: 21),
              onPressed: onEdit,
            ),
            // زر حذف
            IconButton(
              tooltip: 'حذف السؤال',
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 21),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, {bool isMarks = false}) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isMarks
              ? const Color(0xFFF1ECFA)
              : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isMarks ? _purple : const Color(0xFF3B5BDB),
          ),
        ),
      );

  String _formatMarks(double marks) {
    return marks == marks.roundToDouble()
        ? marks.toInt().toString()
        : marks.toString();
  }
}
