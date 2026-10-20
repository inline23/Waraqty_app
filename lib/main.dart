import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waraqty_app/features/exam/cubit/exam_cubit.dart';
import 'package:waraqty_app/features/exam/repos/exam_repository.dart';
import 'package:waraqty_app/features/exam/screens/create_exam_screen.dart';
import 'package:waraqty_app/features/exam/screens/exam_preview_screen.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF431599)),
        scaffoldBackgroundColor: const Color(0xFFF8F6FC),
      ),
      home: Builder(
        builder: (context) {
          return HomeScreen(
            onCreateExam: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateExamScreen()),
              );
            },
            onMyExams: () {},
            onSettings: () {},
            onOpenExam: (exam) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExamPreviewScreen(exam: exam),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
