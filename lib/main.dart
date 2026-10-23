
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:waraqty_app/features/exam/cubit/exam_cubit.dart';
import 'package:waraqty_app/features/exam/repos/exam_repository.dart';
import 'package:waraqty_app/features/exam/screens/create_exam_screen.dart';
import 'package:waraqty_app/features/exam/screens/exam_preview_screen.dart';
import 'package:waraqty_app/features/exam/screens/my_exam_screen.dart';
import 'package:waraqty_app/features/home/screens/home_screen.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => ExamCubit(ExamRepository()),
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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const Color purple = Color(0xFF431599);

  int _selectedIndex = 0;

  void _openCreateExam() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateExamScreen(),
      ),
    );
  }

  void _openExam(exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamPreviewScreen(exam: exam),
      ),
    );
  }

  void _openMyExams() {
    setState(() => _selectedIndex = 1);
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
          ),
          MyExamsScreen(
            onOpenExam: _openExam,
            onCreateExam: _openCreateExam,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
        ],
      ),
    );
  }
}
