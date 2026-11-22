import 'package:url_launcher/url_launcher.dart';

/// فتح الروابط الخارجية بعد أن يضبط المطوّر قيم [AppConfig].
class ExternalLinks {
  const ExternalLinks._();

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return false;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) return false;
    final uri = Uri(scheme: 'mailto', path: trimmed);
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
