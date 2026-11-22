import 'package:flutter/material.dart';

import '../content/privacy_policy_content.dart';
import '../widgets/legal_document_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: PrivacyPolicyContent.title,
      lastUpdated: PrivacyPolicyContent.lastUpdated,
      sections: PrivacyPolicyContent.sections,
    );
  }
}
