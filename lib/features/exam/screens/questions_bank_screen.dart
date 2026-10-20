import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/exam_cubit.dart';
import '../models/question_model.dart';
import 'question_type_screen.dart';
import 'exam_preview_screen.dart';
import 'create_exam_screen.dart';

class QuestionsBankScreen extends StatelessWidget {
  const QuestionsBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<ExamCubit, ExamState>(
        builder: (context, state) {
          final exam = context.read<ExamCubit>().draft;
          if (exam == null) {
            return const Scaffold(body: Center(child: Text('مفيش امتحان قيد الإنشاء. ابدأ بإنشاء امتحان جديد.')));
          }
          return Scaffold(
            backgroundColor: waraqtyBackground,
            appBar: AppBar(
              backgroundColor: waraqtyBackground, elevation: 0, title: const Text('بنك الأسئلة'),
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              actions: [IconButton(tooltip: 'إلغاء المسودة', icon: const Icon(Icons.close), onPressed: () {
                context.read<ExamCubit>().clearDraft(); Navigator.popUntil(context, (route) => route.isFirst);
              })],
            ),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              const _StepHeader(step: 2, title: 'إضافة الأسئلة', subtitle: 'أضف الأسئلة التي تريدها للامتحان'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const CircleAvatar(backgroundColor: Color(0xFFE9DDFF), child: Icon(Icons.analytics_outlined, color: Color(0xFF431599))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${exam.questions.length} أسئلة مسجلة', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(exam.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE9DDFF), borderRadius: BorderRadius.circular(24)),
                    child: Text('المجموع: ${exam.totalMarks.toStringAsFixed(exam.totalMarks % 1 == 0 ? 0 : 1)} درجة', style: const TextStyle(color: Color(0xFF431599), fontWeight: FontWeight.bold))),
                ]),
              ),
              const SizedBox(height: 20),
              if (exam.questions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: const Column(children: [
                    Icon(Icons.description_outlined, size: 70, color: Color(0xFFD0BCFF)),
                    SizedBox(height: 12),
                    Text('لم تتم إضافة أي أسئلة بعد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('ابدأ بإضافة أول سؤال للامتحان. يمكنك إضافة أسئلة من أنواع مختلفة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  ]),
                )
              else
                ...exam.questions.asMap().entries.map((entry) => _QuestionTile(index: entry.key, question: entry.value)),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF431599), minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionTypeScreen())),
                icon: const Icon(Icons.add), label: Text(exam.questions.isEmpty ? 'إضافة أول سؤال للامتحان' : 'إضافة سؤال آخر'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: const Color(0xFF431599)),
                onPressed: () => Navigator.pop(context), icon: const Icon(Icons.edit_outlined), label: const Text('تعديل بيانات الامتحان'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: const Color(0xFF431599)),
                onPressed: exam.questions.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamPreviewScreen(exam: exam))),
                icon: const Icon(Icons.visibility_outlined), label: const Text('معاينة ورقة الامتحان'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: exam.questions.isEmpty ? Colors.grey : const Color(0xFF431599), minimumSize: const Size.fromHeight(52)),
                onPressed: exam.questions.isEmpty ? null : () async {
                  await context.read<ExamCubit>().saveDraft();
                  if (!context.mounted) return;
                  final currentState = context.read<ExamCubit>().state;
                  if (currentState is ExamOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentState.message)));
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else if (currentState is ExamFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentState.errorMessage)));
                  }
                },
                icon: const Icon(Icons.save_outlined), label: const Text('حفظ الامتحان'),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int index; final QuestionModel question;
  const _QuestionTile({required this.index, required this.question});
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFE9DDFF), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF431599)))),
      title: Text(question.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${question.type.arabicName} • ${question.marks} درجة'),
      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => showDialog<void>(
        context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('حذف السؤال؟'), content: const Text('هل تريد حذف هذا السؤال من الامتحان؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            TextButton(onPressed: () { context.read<ExamCubit>().deleteQuestion(question.id); Navigator.pop(dialogContext); }, child: const Text('حذف')),
          ],
        ),
      )),
    ),
  );
}
class _StepHeader extends StatelessWidget {
  final int step; final String title; final String subtitle;
  const _StepHeader({required this.step, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    CircleAvatar(backgroundColor: const Color(0xFF431599), child: Text('$step', style: const TextStyle(color: Colors.white))),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(subtitle, style: const TextStyle(color: Colors.black54)),
    ])),
  ]);
}
