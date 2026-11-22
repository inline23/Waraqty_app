import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../content/legal_section.dart';

class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'آخر تحديث: $lastUpdated',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final paragraph in section.paragraphs) ...[
              SelectableText(
                paragraph,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.85,
                  color: Color(0xFF3A3150),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
