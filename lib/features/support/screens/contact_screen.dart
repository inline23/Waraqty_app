import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_config.dart';
import '../../../core/external_links.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  bool get _hasEmail => AppConfig.supportEmail.trim().isNotEmpty;

  Future<void> _send(BuildContext context) async {
    final opened = await ExternalLinks.sendEmail(AppConfig.supportEmail);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('تعذر فتح تطبيق البريد على هذا الجهاز.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'تواصل معنا',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لو حابب تتواصل بخصوص التطبيق أو سياسة الخصوصية، استخدم بريد الدعم الرسمي.',
            style: TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF3A3150)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: _hasEmail
                ? SelectableText(
                    AppConfig.supportEmail.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  )
                : const Text(
                    AppConfig.supportEmailPlaceholder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _hasEmail
                ? 'اضغط الزر لفتح تطبيق البريد وكتابة رسالة إلى هذا العنوان.'
                : 'بريد الدعم غير مُضاف بعد. سيظهر العنوان الرسمي هنا عند إضافته، ولن يُعرض بريد غير حقيقي.',
            style: const TextStyle(fontSize: 13, height: 1.7, color: Colors.black54),
          ),
          if (_hasEmail) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _send(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.outgoing_mail),
              label: const Text(
                'إرسال رسالة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
