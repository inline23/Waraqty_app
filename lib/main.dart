
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/about/screens/about_screen.dart';
import 'package:waraqty_app/features/legal/screens/privacy_policy_screen.dart';
import 'package:waraqty_app/features/legal/screens/terms_screen.dart';

import 'package:waraqty_app/features/splash/view/splash_screen.dart';

import 'package:waraqty_app/features/exam/cubit/exam/exam_cubit.dart';
import 'package:waraqty_app/features/exam/cubit/questions/question_bank_cubit.dart';

import 'package:waraqty_app/features/exam/models/exam_model.dart';

import 'package:waraqty_app/features/exam/repos/exam_repository.dart';
import 'package:waraqty_app/features/exam/repos/question_bank_repository.dart';

import 'package:waraqty_app/features/exam/screens/create_exam_screen.dart';
import 'package:waraqty_app/features/exam/screens/exam_preview_screen.dart';
import 'package:waraqty_app/features/exam/screens/my_exam_screen.dart';
import 'package:waraqty_app/features/exam/screens/saved_questions_screen.dart';

import 'package:waraqty_app/features/home/screens/home_screen.dart';
import 'package:waraqty_app/features/support/screens/contact_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final examRepository = ExamRepository();
  final bankRepository = QuestionBankRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ExamCubit(
            examRepository,
            bankRepository: bankRepository,
          ),
        ),

        BlocProvider(
          create: (_) => QuestionBankCubit(
            bankRepository,
            examRepository,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ورقتي',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF431599),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6FC),
      ),

      home: SplashScreen(
        nextScreen: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _openCreateExam() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateExamScreen(),
      ),
    );
  }

  void _openExam(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamPreviewScreen(exam: exam),
      ),
    );
  }

  void _openHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }


  void _openMyExams() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openSavedQuestions() {
    setState(() {
      _selectedIndex = 2;
    });

    context.read<QuestionBankCubit>().load();
  }

  
  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // صفحات المعلومات والسياسات
  void _openAbout() {
    _openPage(const AboutScreen());
  }

  void _openPrivacy() {
    _openPage(const PrivacyPolicyScreen());
  }

  void _openTerms() {
    _openPage(const TermsScreen());
  }

  void _openContact() {
    _openPage(const ContactScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            onCreateExam: _openCreateExam,
            onMyExams: _openMyExams,
            onSettings: () {},
            onOpenExam: _openExam,

            // القائمة الجانبية
            onHome: _openHome,
            onSavedQuestions: _openSavedQuestions,
            onAbout: _openAbout,
            onPrivacy: _openPrivacy,
            onTerms: _openTerms,
            onContact: _openContact,
          ),

          MyExamsScreen(
            onOpenExam: _openExam,
            onCreateExam: _openCreateExam,
          ),

          const SavedQuestionsScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 2) {
            context.read<QuestionBankCubit>().load();
          }
        },

        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF0E8FF),
        elevation: 3,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),

          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'امتحاناتي',
          ),

          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'بنك الأسئلة',
          ),
        ],
      ),
    );
  }
}
