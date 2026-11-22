import 'package:flutter/material.dart';
import 'package:waraqty_app/features/settings/app_version_label.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onHome,
    required this.onExams,
    required this.onQuestionBank,
    required this.onAbout,
    required this.onPrivacy,
    required this.onTerms,
    required this.onContact,
  });

  final VoidCallback onHome;
  final VoidCallback onExams;
  final VoidCallback onQuestionBank;
  final VoidCallback onAbout;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onContact;

  static const Color primary = Color(0xFF431599);
  static const Color lavender = Color(0xFFF1EBFC);

  void _navigate(BuildContext context, VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: () => _navigate(context, onTap),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Icon(icon, color: primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF302442),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 13,
        color: Colors.black26,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 7),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.black45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: const Color(0xFFFAF9FF),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFECE6F5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: lavender,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ورقتي',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'كل امتحاناتك في مكان واحد',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.black54,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _sectionTitle('عن التطبيق'),
                  _item(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    title: 'عن ورقتي',
                    onTap: onAbout,
                  ),
                  _item(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    onTap: onPrivacy,
                  ),
                  _item(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'الشروط والأحكام',
                    onTap: onTerms,
                  ),
                  _item(
                    context: context,
                    icon: Icons.mail_outline_rounded,
                    title: 'تواصل معنا',
                    onTap: onContact,
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFECE6F5))),
              ),
              child: FutureBuilder<String>(
                future: loadAppVersionLabel(),
                builder: (context, snapshot) {
                  final version = snapshot.data ?? '...';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ورقتي',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      Text(
                        'الإصدار $version',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
