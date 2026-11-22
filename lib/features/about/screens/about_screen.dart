import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    (
      Icons.edit_document,
      'إنشاء الامتحان',
      'جهّز الامتحان بخطوات واضحة: البيانات، ثم الأسئلة، ثم المراجعة.',
    ),
    (
      Icons.quiz_outlined,
      'أنواع الأسئلة',
      'اختيار من متعدد، ومقالي، وأكمل، مع درجة لكل سؤال.',
    ),
    (
      Icons.inventory_2_outlined,
      'بنك الأسئلة',
      'أسئلتك تتجمّع على جهازك حسب المادة والصف، وتقدر تعيد استخدامها.',
    ),
    (
      Icons.picture_as_pdf_outlined,
      'تصدير للطباعة',
      'راجع شكل الورقة ثم صدّر ملف PDF بمقاس A4.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'عن ورقتي',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'ورقتي تساعدك تجهّز امتحاناتك وتنظّم أسئلتك وتطلعها جاهزة للطباعة، من غير ما تبعد عن جهازك.',
            style: TextStyle(
              fontSize: 15,
              height: 1.85,
              color: Color(0xFF3A3150),
            ),
          ),
          const SizedBox(height: 18),
          for (final feature in _features) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(feature.$1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.$3,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          const Text(
            'امتحاناتك وبنك أسئلتك يتخزنوا على هذا الجهاز. من القائمة تقدر تقرأ سياسة الخصوصية والشروط.',
            style: TextStyle(
              fontSize: 13,
              height: 1.75,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
