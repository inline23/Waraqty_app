
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../exam/cubit/exam_cubit.dart';

import '../../exam/models/exam_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onCreateExam,
    required this.onMyExams,
    required this.onSettings,
    this.onOpenExam,
  });

  final VoidCallback onCreateExam;
  final VoidCallback onMyExams;
  final VoidCallback onSettings;
  final ValueChanged<ExamModel>? onOpenExam;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF431599);
  static const Color accentColor = Color(0xFF6D42C1);
  static const Color backgroundColor = Color(0xFFF8F6FC);

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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: BlocBuilder<ExamCubit, ExamState>(
            builder: (context, state) {
              final exams = state is ExamLoaded
                  ? state.exams
                  : <ExamModel>[];

              final totalQuestions = exams.fold<int>(
                0,
                (total, exam) => total + exam.questions.length,
              );

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () => context.read<ExamCubit>().fetchExams(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 28),
                          _buildWelcome(),
                          const SizedBox(height: 22),
                          _buildCreateExamCard(),
                          const SizedBox(height: 28),
                          _buildSectionTitle(
                            'نظرة عامة',
                            'تابع إنجازاتك',
                          ),
                          const SizedBox(height: 14),
                          _buildStatistics(
                            exams.length,
                            totalQuestions,
                          ),
                          const SizedBox(height: 30),
                          _buildSectionTitle(
                            'ابدأ بسرعة',
                            'اختر نوع السؤال',
                          ),
                          const SizedBox(height: 14),
                          _buildQuickActions(),
                          const SizedBox(height: 30),
                          _buildRecentHeader(),
                          const SizedBox(height: 14),
                          _buildRecentExams(state, exams),
                          const SizedBox(height: 22),
                          _buildTipCard(),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: primaryColor,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ورقتي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'كل امتحاناتك في مكان واحد',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        _IconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildWelcome() {
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'صباح الخير 👋'
        : hour < 18
            ? 'مساء الخير 👋'
            : 'مساء الخير 👋';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF24163B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'جاهز تحضّر امتحانك الجديد؟',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateExamCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF431599),
            Color(0xFF7047C6),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.edit_document,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'أنشئ امتحانك الأول',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'أضف الأسئلة وحدد الدرجات، وطلّع امتحانك جاهز للطباعة.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onCreateExam,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إنشاء امتحان جديد',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF24163B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(int examCount, int questionCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.description_outlined,
            label: 'الامتحانات',
            value: '$examCount',
            color: const Color(0xFF7047C6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.quiz_outlined,
            label: 'الأسئلة',
            value: '$questionCount',
            color: const Color(0xFF168A77),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.print_outlined,
            label: 'جاهز للطباعة',
            value: '$examCount',
            color: const Color(0xFFE69A30),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (
        title: 'اختيار من متعدد',
        icon: Icons.checklist_rounded,
        color: const Color(0xFF7047C6),
      ),
      (
        title: 'مقالي',
        icon: Icons.draw_outlined,
        color: const Color(0xFF168A77),
      ),
      (
        title: 'أكمل',
        icon: Icons.short_text_rounded,
        color: const Color(0xFFE69A30),
      ),
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: actions.map((action) {
        return InkWell(
          onTap: widget.onCreateExam,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFECE6F5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, color: action.color, size: 20),
                const SizedBox(width: 7),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF35264B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'أحدث الامتحانات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24163B),
            ),
          ),
        ),
        TextButton(
          onPressed: widget.onMyExams,
          child: const Text(
            'عرض الكل',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExams(
    ExamState state,
    List<ExamModel> exams,
  ) {
    if (state is ExamFailure) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            const Text('حصلت مشكلة في تحميل الامتحانات'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<ExamCubit>().fetchExams(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (state is ExamLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (exams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFECE6F5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFF1EBFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                size: 32,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لسه مفيش امتحانات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'ابدأ بإنشاء أول امتحان ليك وهيظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onCreateExam,
              child: const Text('إنشاء امتحان'),
            ),
          ],
        ),
      );
    }

    final recentExams = exams.reversed.take(3).toList();

    return Column(
      children: recentExams.map((exam) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.onOpenExam == null
                ? widget.onMyExams
                : () => widget.onOpenExam!(exam),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECE6F5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EBFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: primaryColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E2041),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${exam.subject} • ${exam.grade}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${exam.questions.length} سؤال • ${exam.totalMarks} درجة',
                          style: const TextStyle(
                            fontSize: 11,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF7E8BF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFD28A16),
            size: 27,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نصيحة ليك',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF684511),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'وزّع درجات الأسئلة بعناية، وتأكد إن مجموع الدرجات مناسب لزمن الامتحان.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: Color(0xFF765D36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                selected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.library_books_outlined,
                label: 'امتحاناتي',
                onTap: widget.onMyExams,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'الإعدادات',
                onTap: widget.onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE6F5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E2041),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: const Color(0xFF431599)),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF431599)
        : Colors.black45;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
