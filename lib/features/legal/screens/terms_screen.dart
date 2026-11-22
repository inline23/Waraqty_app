import 'package:flutter/material.dart';

import '../content/terms_content.dart';
import '../widgets/legal_document_view.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: TermsContent.title,
      lastUpdated: TermsContent.lastUpdated,
      sections: TermsContent.sections,
    );
  }
}
