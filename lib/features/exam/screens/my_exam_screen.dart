
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../models/exam_model.dart';

class MyExamsScreen extends StatefulWidget {
  const MyExamsScreen({
    super.key,
    required this.onOpenExam,
    required this.onCreateExam,
  });

  final ValueChanged<ExamModel> onOpenExam;
  final VoidCallback onCreateExam;

  @override
  State<MyExamsScreen> createState() => _MyExamsScreenState();
}

class _MyExamsScreenState extends State<MyExamsScreen> {
  static const Color purple = Color(0xFF431599);
  static const Color background = Color(0xFFFAF9FF);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExamCubit>().fetchExams();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExamModel> _filterExams(List<ExamModel> exams) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = exams.where((exam) {
      return exam.title.toLowerCase().contains(query) ||
          exam.subject.toLowerCase().contains(query) ||
          exam.grade.toLowerCase().contains(query);
    }).toList();

    filtered.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    return filtered;
  }

  List<ExamModel> _getExams(ExamCubit cubit) {
    return _filterExams(cubit.exams);
  }

  Future<void> _confirmDelete(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الامتحان'),
            content: Text(
              'هل أنت متأكد إنك عايز تحذف "${exam.title}"؟\n'
              'مش هتقدر تسترجعه بعد الحذف.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await context.read<ExamCubit>().deleteExam(exam.id);
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
          title: const Text(
            'امتحاناتي',
            style: TextStyle(
              color: purple,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () =>
                  context.read<ExamCubit>().fetchExams(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: purple,
              ),
            ),
          ],
        ),
        body: BlocConsumer<ExamCubit, ExamState>(
          listener: (context, state) {
            if (state is ExamFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            if (state is ExamOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<ExamCubit>();
            final exams = _getExams(cubit);

            final isLoading = state is ExamLoading;
            final hasError = state is ExamFailure;

            return RefreshIndicator(
              color: purple,
              onRefresh: cubit.fetchExams,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18, 10, 18, 28,
                ),
                children: [
                  _buildIntro(cubit.exams.length),
                  const SizedBox(height: 22),
                  _buildSearch(),
                  const SizedBox(height: 20),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: purple,
                        ),
                      ),
                    )
                  else if (hasError && cubit.exams.isEmpty)
                    _buildError()
                  else if (exams.isEmpty)
                    _buildEmpty()
                  else ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'كل الامتحانات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF292333),
                            ),
                          ),
                        ),
                        Text(
                          '${exams.length} امتحان',
                          style: const TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...exams.map(_buildExamCard),
                  ],
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: widget.onCreateExam,
          backgroundColor: purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('امتحان جديد'),
        ),
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
                  'كل شغلك في مكان واحد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عندك $count امتحان محفوظ. '
                  'تقدر تراجعهم وتجهزهم للطباعة.',
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
          const Icon(
            Icons.folder_copy_outlined,
            size: 48,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: 'ابحث باسم الامتحان أو المادة أو الصف',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: purple,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5DDF3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5DDF3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: purple,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFECE6F5),
        ),
      ),
      child: InkWell(
        onTap: () => widget.onOpenExam(exam),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECFA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: purple,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF292333),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${exam.subject} • ${exam.grade}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'خيارات الامتحان',
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(exam);
                      } else if (value == 'preview') {
                        widget.onOpenExam(exam);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined),
                            SizedBox(width: 10),
                            Text('معاينة وتصدير'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'حذف الامتحان',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  height: 1,
                  color: Color(0xFFECE6F5),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(
                    Icons.quiz_outlined,
                    '${exam.questions.length} سؤال',
                  ),
                  _infoChip(
                    Icons.grade_outlined,
                    '${_formatMarks(exam.totalMarks)} درجة',
                  ),
                  _infoChip(
                    Icons.schedule_outlined,
                    '${exam.durationMinutes} دقيقة',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'اضغط لفتح المعاينة',
                    style: TextStyle(
                      color: purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: purple),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF514663),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final searching = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 45),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFF1ECFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              size: 42,
              color: purple,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searching ? 'ملقيناش امتحان بالاسم ده' : 'لسه مفيش امتحانات',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searching
                ? 'جرّب تبحث بكلمة تانية.'
                : 'أنشئ امتحانك الأول وهيظهر هنا.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.6,
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.onCreateExam,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء امتحان'),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 45),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 45,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text('تعذر تحميل الامتحانات'),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                context.read<ExamCubit>().fetchExams(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  String _formatMarks(double marks) {
    return marks == marks.roundToDouble()
        ? marks.toInt().toString()
        : marks.toString();
  }
}
