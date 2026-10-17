import 'package:flutter/material.dart';
import '../models/question_type.dart';
import 'question_editor_screen.dart';

class QuestionTypeScreen extends StatelessWidget {
  const QuestionTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const types = [
      (QuestionType.multipleChoice, Icons.radio_button_checked, 'سؤال مع بدائل متعددة يختار منها الطالب الإجابة المناسبة.'),
      (QuestionType.complete, Icons.edit_note, 'جمل تحتوي على فراغات يكملها الطالب بالكلمة المناسبة.'),
      (QuestionType.trueFalse, Icons.rule, 'عبارات يحدد الطالب إذا كانت صحيحة أم خاطئة.'),
      (QuestionType.essay, Icons.subject, 'أسئلة تحتاج إلى شرح أو خطوات حل ومساحة للإجابة.'),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FF),
        appBar: AppBar(backgroundColor: const Color(0xFFFAF9FF), elevation: 0, title: const Text('اختر نوع السؤال')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('اختر القالب الأنسب للسؤال الذي تريد إضافته', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ...types.map((item) => Card(
              elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionEditorScreen(type: item.$1))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(radius: 25, backgroundColor: const Color(0xFFE9DDFF), child: Icon(item.$2, color: const Color(0xFF431599))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.$1.arabicName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(item.$3, style: const TextStyle(color: Colors.black54)),
                    ])),
                    const Icon(Icons.arrow_back, color: Color(0xFF431599)),
                  ]),
                ),
              ),
            )),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF431599)),
                SizedBox(width: 10),
                Expanded(child: Text('نصيحة: نوّع أنواع الأسئلة لتقييم فهم الطالب من أكثر من جانب.')),
              ])),
          ],
        ),
      ),
    );
  }
}
