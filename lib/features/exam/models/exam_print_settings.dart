import 'dart:typed_data';

import 'package:flutter/material.dart';

/// القوالب المتاحة لورقة الامتحان PDF.
enum ExamTemplate {
  classic,  // كلاسيكي تقليدي
  modern,   // عصري نظيف
  official; // رسمي مؤسسي

  String get arabicName {
    switch (this) {
      case ExamTemplate.classic:
        return 'كلاسيكي';
      case ExamTemplate.modern:
        return 'عصري';
      case ExamTemplate.official:
        return 'رسمي';
    }
  }

  String get arabicDescription {
    switch (this) {
      case ExamTemplate.classic:
        return 'تصميم أكاديمي تقليدي، رأس واضح وأقسام منظمة';
      case ExamTemplate.modern:
        return 'تصميم عصري نظيف مع مسافات بيضاء وعناوين أنيقة';
      case ExamTemplate.official:
        return 'ورقة امتحانية رسمية مع مساحة للشعار والمؤسسة';
    }
  }

  IconData get icon {
    switch (this) {
      case ExamTemplate.classic:
        return Icons.article_outlined;
      case ExamTemplate.modern:
        return Icons.space_dashboard_outlined;
      case ExamTemplate.official:
        return Icons.account_balance_outlined;
    }
  }
}

/// إعدادات طباعة / تصدير PDF منفصلة عن بيانات الامتحان.
class ExamPrintSettings {
  final ExamTemplate template;
  final String? schoolName;
  final String? headerText;
  final Uint8List? logoImageBytes;
  final Color headerColor;
  final bool showTeacherName;
  final bool showSubjectGrade;
  final bool showDurationMarks;
  final bool showStudentInfo;
  final bool showDecorations;
  final bool showBazmala;

  const ExamPrintSettings({
    this.template = ExamTemplate.classic,
    this.schoolName,
    this.headerText,
    this.logoImageBytes,
    this.headerColor = const Color(0xFF431599),
    this.showTeacherName = true,
    this.showSubjectGrade = true,
    this.showDurationMarks = true,
    this.showStudentInfo = true,
    this.showDecorations = true,
    this.showBazmala = true,
  });

  ExamPrintSettings copyWith({
    ExamTemplate? template,
    String? schoolName,
    String? headerText,
    Uint8List? logoImageBytes,
    bool clearLogo = false,
    Color? headerColor,
    bool? showTeacherName,
    bool? showSubjectGrade,
    bool? showDurationMarks,
    bool? showStudentInfo,
    bool? showDecorations,
    bool? showBazmala,
  }) {
    return ExamPrintSettings(
      template: template ?? this.template,
      schoolName: schoolName ?? this.schoolName,
      headerText: headerText ?? this.headerText,
      logoImageBytes: clearLogo ? null : (logoImageBytes ?? this.logoImageBytes),
      headerColor: headerColor ?? this.headerColor,
      showTeacherName: showTeacherName ?? this.showTeacherName,
      showSubjectGrade: showSubjectGrade ?? this.showSubjectGrade,
      showDurationMarks: showDurationMarks ?? this.showDurationMarks,
      showStudentInfo: showStudentInfo ?? this.showStudentInfo,
      showDecorations: showDecorations ?? this.showDecorations,
      showBazmala: showBazmala ?? this.showBazmala,
    );
  }
}
